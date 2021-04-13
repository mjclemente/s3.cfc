/**
* s3.cfc
* Copyright 2018-2019 Matthew Clemente, Brian Klaas
* Licensed under MIT
*/
component {

  public any function init(
    required string accessKey,
    required string secretKey,
    required string clientRegion ) {

    variables.accessKey = accessKey;
    variables.secretKey = secretKey;
    variables.region = clientRegion;

    return this;
  }

  private any function s3Client() {
    var awsCredentials = createObject( 'java', 'com.amazonaws.auth.BasicAWSCredentials').init( variables.accessKey, variables.secretKey );
    var awsStaticCredentialsProvider = createObject( 'java','com.amazonaws.auth.AWSStaticCredentialsProvider' ).init( awsCredentials );
    return buildFromRegion( awsStaticCredentialsProvider );
  }

  /**
  * @hint Convenience method for putting a file as an object in a bucket
  * @filePath the absolute path to the file being added to the bucket
  * @returns on Success, the putObjectResult object, on Error, an AWS Error object, with Message, ErrorCode, ErrorMessage, and StatusCode keys, among others.
  */
  public any function putFile( required string bucketName, required string key, required string filePath ) {
    var file = createObject( "java", "java.io.File" ).init( filePath );
    var result = this.putObject( bucketName, key, file );
    return result;
  }

  /**
  * @hint Current only sets User Metadata - not set up to handle AWS properties for the metadata
  * todo: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html#object-metadata
  * Metadata can't have spaces. It won't be set if it does
  */
  public any function putFileWithMetadata( required string bucketName, required string key, required string filePath, struct metadata = {} ) {
    var file = createObject( "java", "java.io.File" ).init( filePath );
    var awsRequest = createObject( "java", "com.amazonaws.services.s3.model.PutObjectRequest" ).init( bucketName, key, file );

    var objectMetadata = createObject( "java", "com.amazonaws.services.s3.model.ObjectMetadata" );

    for ( var item in metadata ) {
      if( item == "Content-Type" ){
        objectMetadata.setContentType( metadata[ item ]  );
      } else if ( item == "Content-Encoding" ) {
        objectMetadata.setContentEncoding( metadata[ item ]  );
      } else {
        objectMetadata.addUserMetadata( javacast( "string", item ), javacast( "string", metadata[ item ] ) );
      }
    }

    awsRequest.setMetadata( objectMetadata );
    var result = this.putObject( awsRequest );
    return result;
  }

  /**
  * @hint Used to download a file from AWS and save it somewhere
  * @destination the absolute path where the s3 file object should be saved
  * @returns Not sure the best way to handle this. Currently, if the object is not found, the AWS error is returned, as with `getObject()`. If the download is successful, a boolean true is returned
  */
  public any function downloadFile( required string bucketName, required string key, required string destination ) {
    var awsObject = this.getObject( bucketName, key );

    //object not present
    if ( structKeyExists( awsObject, 'ErrorCode' ) ) return awsObject;

    var inputStream = awsObject.getObjectContent();
    var fos = createObject( "java", "java.io.FileOutputStream" ).init( destination );
    var bos = createObject( "java", "java.io.BufferedOutputStream" ).init( fos );

    var byteArray = createObject( "java", "java.io.ByteArrayOutputStream" ).init().toByteArray();
    var byteArrayClass = byteArray.getClass().getComponentType();
    var aByte = createObject("java","java.lang.reflect.Array").newInstance( byteArrayClass, javaCast( "int", 1024 ) );

    var bytesRead = inputStream.read( aByte );
    while ( bytesRead != -1 ) {
      bos.write( aByte, 0, bytesRead );
      bytesRead = inputStream.read( aByte );
    }
    bos.flush();
    bos.close();
    awsObject.close();
    return true;
  }

  /**
  * @hint Reads the content of files
  * @returns Not sure the best way to handle this. Currently, if the object is not found, the AWS error is returned, as with `getObject()`. Otherwise it returns the string content of the file
  */
  public any function readObject( required string bucketName, required string key ) {
    var awsObject = this.getObject( bucketName, key );

    //object not present
    if ( structKeyExists( awsObject, 'ErrorCode' ) ) return awsObject;

    var s = createObject( "java", "java.util.Scanner" ).init( awsObject.getObjectContent() ).useDelimiter("\\A");
    var result = s.hasNext() ? s.next() : "";
    s.close();
    awsObject.close();
    return result;
  }

  /**
  * @hint convenience method for returning user metadata for an object. Throws an error if the object doesn't exist
  */
  public struct function getObjectUserMetadata( required string bucketName, required string key ) {
    var awsObject = this.getObject( bucketName, key );
    var result = {};
    //object not present
    if ( structKeyExists( awsObject, 'ErrorCode' ) ) throw( object = awsObject );

    result = awsObject.getObjectMetadata().getUserMetadata();
    awsObject.close();
    return result;
  }

  public array function listObjectKeys( required string bucketName ) {
    var keys = [];

    var req = createObject( "java", "com.amazonaws.services.s3.model.ListObjectsV2Request" ).init();
    //req.withBucketName( bucketName ).withMaxKeys( 2 );
    req.withBucketName( bucketName );

    do {
      var result = this.listObjectsV2( req );

      for ( var objectSummary in result.getObjectSummaries() ) {
        keys.append( objectSummary.getKey() );
      }

      var token = result.getNextContinuationToken();
      if ( !isNull( token ) ) req.setContinuationToken( token );

    } while ( result.isTruncated() );

    return keys;
  }

  public any function onMissingMethod( missingMethodName, missingMethodArguments ) {
    var methodArguments = [];
    for ( var index in missingMethodArguments ) {
      methodArguments.append( missingMethodArguments[ index ] );
    }
    try {
      var result = invoke( s3Client(), missingMethodName, methodArguments );
    } catch ( any e ) {
      result = e;
    }

    return result;
  }

  /**
  * @hint Takes a region and combines it with the credentials to return the s3 client
  */
  private any function buildFromRegion( awsStaticCredentialsProvider ) {

    return createObject( 'java', 'com.amazonaws.services.s3.AmazonS3ClientBuilder').standard().withCredentials( awsStaticCredentialsProvider ).withRegion( variables.region ).build();
  }

}
