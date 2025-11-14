public class ContentVersionTriggerHandler {

    @future(callout=true)
    public static void callGDrive(String cvID, String recordId) {
        try {
            // 1️⃣ Query the file (ContentVersion)
            ContentVersion cv = [
                SELECT Id, Title, VersionData, PathOnClient 
                FROM ContentVersion 
                WHERE Id = :cvID 
                LIMIT 1
            ];

            Blob fileBlob = cv.VersionData;
            String objectType = ((Id)recordId).getSObjectType().getDescribe().getName();
 // e.g. 'Account' or 'Contact'
            String folderId = getOrCreateFolder(objectType); // Step 2: check or create folder

            // 2️⃣ File upload metadata (file name = recordId)
            String fileName = recordId;
            String fileExtension = cv.PathOnClient != null && cv.PathOnClient.contains('.') 
                ? cv.PathOnClient.substring(cv.PathOnClient.lastIndexOf('.') + 1).toLowerCase()
                : 'txt';
            String contentType = getContentType(fileExtension);

            String metadataJson = '{"name": "' + fileName + '", "parents": ["' + folderId + '"]}';

            // 3️⃣ Build multipart upload body
            String boundary = '-------314159265358979323846';
            String delimiter = '\r\n--' + boundary + '\r\n';
            String closeDelimiter = '\r\n--' + boundary + '--';
            String body = delimiter + 'Content-Type: application/json\r\n\r\n' + metadataJson +
                          delimiter + 'Content-Type: ' + contentType + '\r\n' +
                          'Content-Transfer-Encoding: base64\r\n\r\n' +
                          EncodingUtil.base64Encode(fileBlob) + closeDelimiter;

            // 4️⃣ Make upload callout
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'multipart/related; boundary="' + boundary + '"');
            req.setMethod('POST');
            req.setEndpoint('callout:google_drive_named_cred/upload/drive/v3/files?uploadType=multipart');
            req.setBody(body);
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                System.debug('✅ File uploaded successfully for record ' + recordId);
            } else {
                System.debug('❌ Upload failed: ' + res.getStatus() + ' -> ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('⚠️ Error in callGDrive: ' + e.getMessage());
        }
    }

    // 🧩 Helper: Get or Create folder by name (object type)
    private static String getOrCreateFolder(String folderName) {
        try {
            // 1️⃣ Check if folder exists
            HttpRequest getReq = new HttpRequest();
            getReq.setMethod('GET');
            getReq.setEndpoint('callout:google_drive_named_cred/drive/v3/files?q=name=\'' + folderName + '\' and mimeType=\'application/vnd.google-apps.folder\'&fields=files(id,name)');
            getReq.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse getRes = http.send(getReq);

            if (getRes.getStatusCode() == 200 && getRes.getBody().contains('"id"')) {
                Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(getRes.getBody());
                List<Object> files = (List<Object>) json.get('files');
                if (!files.isEmpty()) {
                    Map<String, Object> folderData = (Map<String, Object>) files[0];
                    return (String) folderData.get('id');
                }
            }

            // 2️⃣ Folder not found → create one
            HttpRequest postReq = new HttpRequest();
            postReq.setEndpoint('callout:google_drive_named_cred/drive/v3/files');
            postReq.setHeader('Content-Type', 'application/json');
            postReq.setMethod('POST');
            postReq.setBody('{"name": "' + folderName + '", "mimeType": "application/vnd.google-apps.folder"}');

            HttpResponse postRes = http.send(postReq);

            if (postRes.getStatusCode() == 200 || postRes.getStatusCode() == 201) {
                Map<String, Object> folder = (Map<String, Object>) JSON.deserializeUntyped(postRes.getBody());
                return (String) folder.get('id');
            } else {
                System.debug('❌ Failed to create folder: ' + postRes.getBody());
            }
        } catch (Exception e) {
            System.debug('⚠️ Error in getOrCreateFolder: ' + e.getMessage());
        }
        return null;
    }

    // 🧩 Helper: determine MIME type
    private static String getContentType(String ext) {
        Map<String, String> types = new Map<String, String>{
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'pdf' => 'application/pdf',
            'doc' => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'xls' => 'application/vnd.ms-excel',
            'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'ppt' => 'application/vnd.ms-powerpoint',
            'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        };
        return types.containsKey(ext) ? types.get(ext) : 'application/octet-stream';
    }
}
/*
--------------Trigger-------------------
trigger ContentVersionTrigger on ContentVersion (after insert) {
    List<ContentDocumentLink> cdlList = [
        SELECT ContentDocumentId, LinkedEntityId 
        FROM ContentDocumentLink 
        WHERE ContentDocumentId IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :Trigger.new)
    ];

    Map<Id, Id> versionToRecord = new Map<Id, Id>();
    for (ContentDocumentLink cdl : cdlList) {
        for (ContentVersion cv : Trigger.new) {
            if (cv.ContentDocumentId == cdl.ContentDocumentId) {
                versionToRecord.put(cv.Id, cdl.LinkedEntityId);
            }
        }
    }

    for (Id cvId : versionToRecord.keySet()) {
        ContentVersionTriggerHandler.callGDrive(String.valueOf(cvId), String.valueOf(versionToRecord.get(cvId)));

    }
}


*/
