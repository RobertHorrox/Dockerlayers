# syntax=docker/dockerfile:1.0.0-experimental
ARG python_version=python3
FROM registry.hub.docker.com/library/python:3.7.4-buster@sha256:2607e636b8bdd389a5298e3e86c3035d5eb400e9caaa1b18615a960fb1b772ad AS internal-python3
RUN mkdir /app && pip install --no-cache pipenv
WORKDIR /app
FROM registry.hub.docker.com/library/python:2.7.16-buster@sha256:114960025593fb429c8e009b46f6e9cbad38b2214e8f85e49a82dc029db255ce AS internal-python2
RUN mkdir /app && pip install --no-cache pipenv
WORKDIR /app
# Cache both the Python2 and Python 3 base images.  Pull uses full path to ensure image target as well as using
# SHA digest which is immutable unlike docker tags.  Pins Image to ensure no unexpected changes in base.

LABEL company=""
LABEL maintainer=""

FROM internal-python3 AS lock-python3
COPY Pipfile .
RUN pipenv lock --clear

FROM internal-python2 AS lock-python2
COPY Pipfile .
RUN pipenv lock --clear

FROM scratch as export-lock-files
COPY --from=lock-python3 /app/Pipfile.lock Pipfile.python3.lock
COPY --from=lock-python2 /app/Pipfile.lock Pipfile.python2.lock

FROM internal-python3 AS app-deps-python3
COPY --from=lock-python3 /app/Pipfile* ./
RUN pipenv install --clear --deploy --system --ignore-pipfile --dev

FROM internal-python2 AS app-deps-python2
COPY --from=lock-python2 /app/Pipfile* ./
RUN pipenv install --clear --deploy --system --ignore-pipfile --dev

FROM app-deps-${python_version} as dev_image
RUN groupadd -r pyapp && useradd -r -s /bin/false -g pyapp pyapp && chown -R pyapp:pyapp /app
USER pyapp
ADD --chown=pyapp:pyapp . .
ADD . .
ENV FLASK_APP=web.py
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]
