# Salesforce Integration with Google Drive
## Requirement
Whenever user uploades any file in salesforce the, so a folder in google drive should be made with the name of the object from which the file has been uploaded. Then a folder with the name of record id should be made from the record the file has been uploaded, in the recordId named folder the file should be uploaded with the same name of the file as it is originally.
The struture somewhat should look like this: 
``` bash
Google Drive
  |----Object Name (Account)
            |---- Record Id (001xxx.....)
                  |---- File (My File)
```
### Version 1
Working properly

### Final Version
This version working properly as intented
The Trigger handler and Trigger code is in the same file , Both need to separated
