public class ContentVersionTriggerHandler {
    @future(callout=true)
    public static void callGDrive(String cvID) {
        try {
            ContentVersion cv = [SELECT Id, Title, ContentDocumentId, VersionData, PathOnClient FROM ContentVersion WHERE Id = :cvID LIMIT 1];
            Blob myBlob = cv.VersionData;
            String fileName = cv.PathOnClient != null ? cv.PathOnClient : cv.Title;
            String fileExtension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            String contentType;
            if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
                contentType = 'image/jpeg';
            } else if (fileExtension == 'png') {
                contentType = 'image/png';
            } else if (fileExtension == 'pdf') {
                contentType = 'application/pdf';
            } else if (fileExtension == 'doc' || fileExtension == 'docx') {
                contentType = 'application/msword';
            } else if (fileExtension == 'xls' || fileExtension == 'xlsx') {
                contentType = 'application/vnd.ms-excel';
            } else if (fileExtension == 'ppt' || fileExtension == 'pptx') {
                contentType = 'application/vnd.ms-powerpoint';
            } else {
                contentType = 'application/octet-stream';
            }
            String metadataJson = '{"name": "' + fileName + '"}';
            String boundary = '-------314159265358979323846';
            String delimiter = '\r\n--' + boundary + '\r\n';
            String closeDelimiter = '\r\n--' + boundary + '--';
            String body = delimiter + 'Content-Type: application/json\r\n\r\n' + metadataJson + delimiter + 
                          'Content-Type: ' + contentType + '\r\n' + 'Content-Transfer-Encoding: base64\r\n\r\n' + 
                          EncodingUtil.base64Encode(myBlob) + closeDelimiter;
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('Content-Type', 'multipart/related; boundary="' + boundary + '"');
            req1.setMethod('POST');
            req1.setEndpoint('callout:google_drive_named_cred/v3/files?uploadType=multipart');
            req1.setBody(body);
            req1.setTimeout(60 * 1000);
            Http h1 = new Http();
            HttpResponse resp1 = h1.send(req1);
            if (resp1.getStatusCode() == 200 || resp1.getStatusCode() == 201) 
            {
                System.debug('File uploaded successfully with name: ' + fileName);
            }
            else 
            {
                throw new CalloutException('Failed to upload file. Status: ' + resp1.getBody());
            }
        } 
        catch (Exception e)
        {
            System.debug('Error in uploading file: ' + e.getMessage());
        }
    }
}


/*
----------Trigger-------------------
-----------Write this trigger on content version----------
---------------replace your named credentials-------------


trigger ContentVersionTrigger on ContentVersion (after insert) {
    for(ContentVersion cv : trigger.New)
    {
        ContentVersionTriggerHandler.callGDrive(cv.Id);
    }
}

*/
