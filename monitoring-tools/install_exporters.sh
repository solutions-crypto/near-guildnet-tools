#!/bin/bash

cd /tmp && wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xvfz node_exporter-*.*-amd64.tar.gz && cd node_exporter-*.*-amd64
sudo cp node_exporter /usr/local/bin

