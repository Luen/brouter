# The build stage runs on the build host for every target platform, because
# the jar is architecture independent. Only the runtime stage runs per
# platform.
FROM --platform=$BUILDPLATFORM eclipse-temurin:17-jdk-jammy AS build

WORKDIR /brouter
COPY . .

RUN sed -i 's/\r$//' gradlew && chmod +x gradlew
RUN --mount=type=cache,target=/root/.gradle ./gradlew --no-daemon clean build

# Fork: runtime keeps cron + weekly segment refresh, so it runs as root.
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && apt-get install -y \
    cron \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /segments4 /customprofiles && touch /var/log/cron.log

COPY --from=build /brouter/brouter-server/build/libs/brouter-*-all.jar /brouter.jar
COPY --from=build --chmod=755 /brouter/misc/scripts/standalone/server.sh /bin/server.sh
COPY --from=build /brouter/misc/profiles2/ /profiles2/
COPY --from=build --chmod=755 /brouter/misc/scripts/download_segments.sh /bin/download_segments.sh
COPY --chmod=755 docker-entrypoint.sh /bin/docker-entrypoint.sh

ENV CLASSPATH=/brouter.jar \
    SEGMENTSPATH=/segments4 \
    PROFILESPATH=/profiles2 \
    CUSTOMPROFILESPATH=/customprofiles

EXPOSE 17777

ENTRYPOINT ["/bin/docker-entrypoint.sh"]
CMD ["/bin/server.sh"]
