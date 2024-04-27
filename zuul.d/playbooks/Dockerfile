ARG FROM="requirements:latest"
FROM ${FROM} AS requirements

FROM nginx:alpine

# Previously built requirements image
COPY --from=requirements / /usr/share/nginx/html
RUN cd /usr/share/nginx/html; tar c -f wheels.tar.gz -z  *.whl *.txt; rm -f *.whl
