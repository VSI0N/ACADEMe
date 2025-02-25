# Run this file to get a secret key and set it in JWT_SECRET_KEY in the .env file

import secrets

print(secrets.token_urlsafe(32))  # Generates a secure random key
