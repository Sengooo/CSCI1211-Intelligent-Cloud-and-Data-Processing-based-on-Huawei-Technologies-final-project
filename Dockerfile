FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install dependencies
# We install inside /app
COPY booking_clone/requirements.txt /app/
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy project and seed data
COPY booking_clone /app/
COPY seed.json /seed.json

# Run migrations and seed database
RUN python manage.py migrate && \
    python seed_db.py && \
    python create_su.py

# Expose port
EXPOSE 8000

# Run the Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
