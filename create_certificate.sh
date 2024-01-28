#!/bin/bash

# Configuration variables
CERT_DOMAIN="ecs-alb-638370155.eu-west-2.elb.amazonaws.com"
PRIVATE_KEY_FILE="privatekey.pem"
CERT_FILE="certificate.pem"
REGION="eu-west-2" # Change to your AWS region

# Generate a private key
openssl genrsa -out $PRIVATE_KEY_FILE 2048

# Generate a self-signed certificate
openssl req -new -x509 -key $PRIVATE_KEY_FILE -out $CERT_FILE -days 365 -subj "/CN=$CERT_DOMAIN"

# Upload the certificate to ACM
CERT_ARN=$(aws acm import-certificate \
  --certificate fileb://$CERT_FILE \
  --private-key fileb://$PRIVATE_KEY_FILE \
  --region $REGION \
  --query 'CertificateArn' --output text)

# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "Certificate uploaded successfully."
    echo "Certificate ARN: $CERT_ARN"
else
    echo "Certificate upload failed."
fi

# Clean up local files
rm $PRIVATE_KEY_FILE $CERT_FILE