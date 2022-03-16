# SyncStorage

Property wrapper for storing and synchronising property values via iCloud Key-Value Storage. Functions as a local persistent storage when iCloud is unavailable. Can be used to replace `@AppStorage` property wrapper.

        @SyncStorage("music") var musicEnabled = true
        @SyncStorage("sfx") var sfxEnabled = true
        @SyncStorage("music volume") var musicVolume = 1.0
        @SyncStorage("sfx volume") var sfxVolume = 1.0
        
The `key` name must be present. Default value will be assigned unless a different property value is already present in iCloud KVS.




