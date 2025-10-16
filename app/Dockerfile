FROM python:3.11-slim

WORKDIR /helloapp

RUN pip install --no-cache-dir fastapi uvicorn

COPY ./app /helloapp

# 5. Expose the port FastAPI runs on
EXPOSE 8000

# 6. Command to run the app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
