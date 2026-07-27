FROM python:3.14-alpine

RUN adduser -D -u 10001 appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

USER 10001
EXPOSE 8080

CMD ["python", "app.py"]
