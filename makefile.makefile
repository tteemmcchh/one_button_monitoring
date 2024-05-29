# Define versions
PROMTAIL_VERSION := 2.9.4
LOKI_VERSION := 2.9.4
GRAFANA_VERSION := 11.0.0
NODE_EXPORTER_VERSION := 1.8.1
PROMETHEUS_VERSION := 2.45.5

# Define URLs
PROMTAIL_URL := https://github.com/grafana/loki/releases/download/v$(PROMTAIL_VERSION)/promtail-linux-amd64.zip
LOKI_URL := https://github.com/grafana/loki/releases/download/v$(LOKI_VERSION)/loki-linux-amd64.zip
GRAFANA_URL := https://dl.grafana.com/oss/release/grafana-$(GRAFANA_VERSION).linux-amd64.tar.gz
NODE_EXPORTER_URL := https://github.com/prometheus/node_exporter/releases/download/v$(NODE_EXPORTER_VERSION)/node_exporter-$(NODE_EXPORTER_VERSION).linux-amd64.tar.gz
PROMETHEUS_URL := https://github.com/prometheus/prometheus/releases/download/v$(PROMETHEUS_VERSION)/prometheus-$(PROMETHEUS_VERSION).linux-amd64.tar.gz

# Define install directories
INSTALL_DIR := /usr/local/bin
PROMTAIL_DIR := /etc/promtail
LOKI_DIR := /etc/loki
GRAFANA_DIR := /usr/local/grafana
NODE_EXPORTER_DIR := /etc/node_exporter
PROMETHEUS_DIR := /usr/local/prometheus

all: install_promtail install_loki install_grafana

install_promtail:
	@echo "Installing Promtail..."
	curl -LO $(PROMTAIL_URL)
	unzip promtail-linux-amd64.zip
	sudo mv promtail-linux-amd64 $(INSTALL_DIR)/promtail
	sudo chmod +x $(INSTALL_DIR)/promtail
	sudo mkdir -p $(PROMTAIL_DIR)
	sudo wget https://raw.githubusercontent.com/grafana/loki/v$(PROMTAIL_VERSION)/clients/cmd/promtail/promtail-local-config.yaml
	sudo mv promtail-local-config.yaml $(PROMTAIL_DIR)
	sudo touch /etc/systemd/system/promtail.service

	echo "[Unit]\n\
	Description=Promtail Service\n\
	After=network.target\n\
	[Service]\n\
	User=nobody\n\
	ExecStart=$(INSTALL_DIR)/promtail -config.file=$(PROMTAIL_DIR)/promtail-local-config.yaml\n\
	Restart=on-failure\n\
	[Install]\n\
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/promtail.service > /dev/null
	
	sudo systemctl daemon-reload
	sudo systemctl start promtail
	sudo systemctl enable promtail

install_loki:
	@echo "Installing Loki..."
	curl -LO $(LOKI_URL)
	unzip loki-linux-amd64.zip
	sudo mv loki-linux-amd64 $(INSTALL_DIR)/loki
	sudo chmod +x $(INSTALL_DIR)/loki
	sudo mkdir -p $(LOKI_DIR)
	sudo wget https://raw.githubusercontent.com/grafana/loki/v$(LOKI_VERSION)/cmd/loki/loki-local-config.yaml
	sudo mv loki-local-config.yaml $(LOKI_DIR)/loki-local-config.yaml
	sudo touch /etc/systemd/system/loki.service

	echo "[Unit]\n\
	Description=Loki Service\n\
	After=network.target\n\
	[Service]\n\
	User=nobody\n\
	ExecStart=$(INSTALL_DIR)/loki -config.file=$(LOKI_DIR)/loki-local-config.yaml\n\
	Restart=on-failure\n\
	[Install]\n\
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/loki.service > /dev/null

	sudo systemctl daemon-reload
	sudo systemctl start loki
	sudo systemctl enable loki

install_grafana:
	@echo "Installing Grafana..."
	curl -LO $(GRAFANA_URL)
	tar -zxvf grafana-$(GRAFANA_VERSION).linux-amd64.tar.gz
	sudo mv grafana-v$(GRAFANA_VERSION) $(GRAFANA_DIR)
	sudo touch /etc/systemd/system/grafana.service

	echo "[Unit]\n\
	Description=Grafana Service\n\
	After=network.target\n\
	\n\
	[Service]\n\
	User=nobody\n\
	ExecStart=$(GRAFANA_DIR)/bin/grafana-server --config=$(GRAFANA_DIR)/conf/defaults.ini --homepath=$(GRAFANA_DIR)\n\
	\n\
	[Install]\n\
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/grafana.service > /dev/null

	sudo systemctl daemon-reload
	sudo systemctl enable grafana
	sudo systemctl start grafana
	


install_node_exporter:
	@echo "Installing Node_exporter..."
	curl -LO $(NODE_EXPORTER_URL)
	tar -zxvf node_exporter-$(NODE_EXPORTER_VERSION).linux-amd64.tar.gz
	sudo mv node_exporter-$(NODE_EXPORTER_VERSION).linux-amd64 $(INSTALL_DIR)
	sudo touch /etc/systemd/system/node_exporter.service

	echo "[Unit]\n\
	Description=Node Exporter\n\
	Wants=network-online.target\n\
	After=network-online.target\n\
	[Service]\n\
	User=nobody\n\
	Type=simple\n\
	ExecStart=$(NODE_EXPORTER_DIR)/node_exporter\n\
	[Install]\n\
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/node_exporter.service > /dev/null

	sudo systemctl daemon-reload
	sudo systemctl start node_exporter
	sudo systemctl enable node_exporter

install_prometheus:
	@echo "Installing Prometheus..."
	curl -LO $(PROMETHEUS_URL)
	tar -zxvf prometheus-$(PROMETHEUS_VERSION).linux-amd64.tar.gz
	sudo mv prometheus-$(PROMETHEUS_VERSION).linux-amd64 $(PROMETHEUS_DIR)
	sudo touch /etc/systemd/system/prometheus.service

	echo "[Unit]\n\
	Description=Prometheus\n\
	Wants=network-online.target\n\
	After=network-online.target\n\
	[Service]\n\
	User=nobody\n\
	Type=simple\n\
	ExecStart=$(PROMETHEUS_DIR)/prometheus\n\
	[Install]\n\
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/prometheus.service > /dev/null

	sudo systemctl daemon-reload
	sudo systemctl start prometheus
	sudo systemctl enable prometheus


clean:
	@echo "Cleaning up..."
	rm -f promtail-linux-amd64.zip loki-linux-amd64.zip grafana-$(GRAFANA_VERSION)-linux-amd64.tar.gz
	rm -rf grafana-$(GRAFANA_VERSION)
	rm - rf node_exporter-1.8.1.linux-amd64

.PHONY: all install_promtail install_loki install_grafana clean
