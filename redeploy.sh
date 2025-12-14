docker stop getajob-web \
  && docker container rm getajob-web \
  && docker image rm getajob-web \
  && docker build --no-cache -t getajob-web . \
  && ./run.sh \
  && docker logs -f getajob-web