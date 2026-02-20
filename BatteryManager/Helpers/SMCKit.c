#include "SMCKit.h"
#include <stdio.h>
#include <string.h>

static kern_return_t SMCCall(io_connect_t conn, uint32_t selector, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure) {
    size_t inputStructureSize = sizeof(SMCKeyData_t);
    size_t outputStructureSize = sizeof(SMCKeyData_t);
    
    return IOConnectCallStructMethod(conn, selector, inputStructure, inputStructureSize, outputStructure, &outputStructureSize);
}

kern_return_t SMCOpen(io_connect_t *conn) {
    kern_return_t result;
    mach_port_t masterPort;
    io_iterator_t iterator;
    io_object_t device;
    
    result = IOMainPort(MACH_PORT_NULL, &masterPort);  // Changed from IOMasterPort to IOMainPort
    if (result != kIOReturnSuccess) {
        return result;
    }
    
    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    if (result != kIOReturnSuccess) {
        return result;
    }
    
    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0) {
        return kIOReturnError;
    }
    
    result = IOServiceOpen(device, mach_task_self(), 0, conn);
    IOObjectRelease(device);
    
    return result;
}

kern_return_t SMCClose(io_connect_t conn) {
    return IOServiceClose(conn);
}

kern_return_t SMCReadKey(io_connect_t conn, const char *key, SMCVal_t *val) {
    kern_return_t result;
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    memset(val, 0, sizeof(SMCVal_t));
    
    inputStructure.key = *((uint32_t*)key);
    inputStructure.data8 = SMC_CMD_READ_KEYINFO;
    
    result = SMCCall(conn, KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess) {
        return result;
    }
    
    val->dataSize = outputStructure.keyInfo.dataSize;
    memcpy(val->dataType, &outputStructure.keyInfo.dataType, 4);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;
    
    result = SMCCall(conn, KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess) {
        return result;
    }
    
    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));
    
    return kIOReturnSuccess;
}

kern_return_t SMCWriteKey(io_connect_t conn, SMCVal_t writeVal) {
    kern_return_t result;
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    
    inputStructure.key = *((uint32_t*)writeVal.key);
    inputStructure.data8 = SMC_CMD_WRITE_BYTES;
    inputStructure.keyInfo.dataSize = writeVal.dataSize;
    memcpy(inputStructure.bytes, writeVal.bytes, sizeof(writeVal.bytes));
    
    result = SMCCall(conn, KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    return result;
}
