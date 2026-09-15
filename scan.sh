#!/bin/bash

IMAGE_NAME=$1

mkdir -p reports

trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --format table \
  --output reports/scan-report.txt \
  "$IMAGE_NAME"

TRIVY_EXIT_CODE=$?

if [ $TRIVY_EXIT_CODE -ne 0 ]; then
    echo "HIGH or CRITICAL vulnerabilities found!"
    exit 1
fi

echo "No HIGH or CRITICAL vulnerabilities found."
echo "Scan report saved to reports/scan-report.txt"