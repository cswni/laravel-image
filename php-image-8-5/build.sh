#!/bin/bash
# Build script for Laravel FrankenPHP image

set -e

IMAGE_NAME="${IMAGE_NAME:-laravel-frankenphp}"
IMAGE_TAG=""
REGISTRY="${REGISTRY:-}"

echo "🏗️  Building Laravel FrankenPHP Image"
echo "   Name: ${IMAGE_NAME}"
echo "   Tag: ${IMAGE_TAG}"
echo ""

if [ -n "$REGISTRY" ]; then
    FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}"
else
    FULL_IMAGE="${IMAGE_NAME}"
fi

echo "📦 Building: ${FULL_IMAGE}"
docker build -t "cswni/fphp:1.0.0" .

echo ""
echo "✅ Build complete!"
echo ""
echo "🚀 To run the container:"
echo "   docker run -d -p 8080:8080 -v \$(pwd)/../agency7:/var/www/html --env-file ../.env ${FULL_IMAGE}"
echo ""
echo "📊 To check PHP extensions:"
echo "   docker run --rm ${FULL_IMAGE} php -m"
echo ""

if [ -n "$REGISTRY" ]; then
    read -p "Push to registry? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📤 Pushing to registry..."
        docker push "${FULL_IMAGE}"
        echo "✅ Push complete!"
    fi
fi

