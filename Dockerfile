FROM gradle:9.3.0-jdk17-jammy AS build

RUN mkdir /tmp/brouter
WORKDIR /tmp/brouter
COPY . .
RUN ./gradlew clean build

FROM openjdk:26-jdk-slim

# Install cron, curl, and procps (for ps command)
RUN apt-get update && apt-get install -y \
    cron \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy BRouter files
COPY --from=build /tmp/brouter/brouter-server/build/libs/brouter-*-all.jar /brouter.jar
COPY --from=build /tmp/brouter/misc/scripts/standalone/server.sh /bin/
COPY --from=build /tmp/brouter/misc/* /profiles2

# Copy download script and make it executable
COPY --from=build /tmp/brouter/misc/scripts/download_segments.sh /bin/download_segments.sh
RUN chmod +x /bin/download_segments.sh

# Create cron log file
RUN touch /var/log/cron.log

# Copy entrypoint script and make it executable
COPY docker-entrypoint.sh /bin/docker-entrypoint.sh
RUN chmod +x /bin/docker-entrypoint.sh

# Create segments directory
RUN mkdir -p /segments4

# Set environment variables for server script
ENV CLASSPATH=/brouter.jar
ENV SEGMENTSPATH=/segments4
ENV PROFILESPATH=/profiles2
ENV CUSTOMPROFILESPATH=/customprofiles

# Set entrypoint
ENTRYPOINT ["/bin/docker-entrypoint.sh"]

# Default command
CMD ["/bin/server.sh"]

