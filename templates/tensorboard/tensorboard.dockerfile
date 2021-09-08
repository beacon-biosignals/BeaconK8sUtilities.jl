FROM python:3.6-buster

# Install boto3
RUN python3 -m pip install --no-cache-dir boto3==1.18.28 tensorboard==2.6.0

# Export port for TensorBoard
EXPOSE 6006
