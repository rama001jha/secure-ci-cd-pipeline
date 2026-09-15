#!/bin/bash

IMAGE_NAME=secure-ci-cd

mkdir -p reports

trivy image \
  --severity HIGH,CRITICAL \
  --format table \
  --output reports/scan-report.txt \
  "$IMAGE_NAME"

echo "Scan report saved to reports/scan-report.txt"