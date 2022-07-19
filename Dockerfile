FROM python:3.10

RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
RUN apt-get update && apt-get install -y jq curl git

WORKDIR /app
COPY main.sh /app/main.sh


ENTRYPOINT [ "bash", "/app/main.sh"]
