/**
* s3.cfc
* Copyright 2018 Matthew Clemente, Brian Klaas
* Licensed under MIT
*/
component {

  public any function init(
    required string accessKey,
    required string secretKey,
    required string clientRegion ) {

    var awsCredentials = createObject( 'java', 'com.amazonaws.auth.BasicAWSCredentials').init( accessKey, secretKey );

    variables.awsStaticCredentialsProvider = createObject( 'java','com.amazonaws.auth.AWSStaticCredentialsProvider' ).init( awsCredentials );

    variables.region = clientRegion;
    variables.s3Client = buildFromRegion();

    return this;
  }

  /**
  * @hint Convenience method for putting a file as an object in a bucket
  * @filePath the absolute path to the file being added to the bucket
  * @returns on Success, the putObjectResult object
  */
  public any function putFile( required string bucketName, required string key, required string filePath ) {
    var file = createObject( "java", "java.io.File" ).init( filePath );
    var result = this.putObject( bucketName, key, file );
    return result;
  }

  /**
  * @hint Used to download a file from AWS and save it somewhere
  * @destination the absolute path where the s3 file object should be saved
  * @returns Not sure the best way to handle this. Currently, if the object is not found, the AWS error is returned, as with `getObject()`. If the download is successful, a boolean true is returned
  */
  public any function downloadFile( required string bucketName, required string key, required string destination ) {
    var awsObject = this.getObject( bucketName, key );

    //file not present
    if ( awsObject.keyExists( 'ErrorCode' ) ) return awsObject;

    var inputStream = awsObject.getObjectContent();
    var fos = createObject( "java", "java.io.FileOutputStream" ).init( destination );
    var bos = createObject( "java", "java.io.BufferedOutputStream" ).init( fos );
    var aByte = javaCast( 'byte[]', [1024] );
    var bytesRead = 0;

    while ( ( bytesRead = inputStream.read( aByte ) ) != -1 ) {
      bos.write( aByte, 0, bytesRead );
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

    //file not present
    if ( awsObject.keyExists( 'ErrorCode' ) ) return awsObject;

    var s = createObject( "java", "java.util.Scanner" ).init( awsObject.getObjectContent() ).useDelimiter("\\A");
    var result = s.hasNext() ? s.next() : "";
    s.close();
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
      var result = invoke( variables.s3Client, missingMethodName, methodArguments );
    } catch ( any e ) {
      result = e;
    }

    return result;
  }

  private void function missingObjectError( required struct awsResponse ) {
    throw(
      message = awsResponse.message,
      type = awsResponse.type,
      detail = awsResponse.detail,
      errorcode = awsResponse.errorCode,
      extendedinfo = awsResponse.extendedInfo,
      object = awsResponse
    );
  }

  /**
  * @hint Takes a region and combines it with the credentials to return the s3 client
  */
  private any function buildFromRegion() {
    return createObject( 'java', 'com.amazonaws.services.s3.AmazonS3ClientBuilder').standard().withCredentials( variables.awsStaticCredentialsProvider ).withRegion( variables.region ).build();
  }

}