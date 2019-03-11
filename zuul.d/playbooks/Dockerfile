FROM nginx:alpine

# Previously built requirements image
COPY --from=openstackhelm/requirements:latest / /usr/share/nginx/html
RUN cd /usr/share/nginx/html; tar c -f wheels.tar.gz -z  *.whl *.txt; rm -f *.whl
