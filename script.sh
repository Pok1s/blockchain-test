#!/bin/bash

show_progress() {
  local duration=$1
  local interval=0.1
  local steps=$(echo "$duration / $interval" | bc)
  local progress=0

  while [ $progress -le $steps ]; do
    local percent=$(echo "scale=2; $progress / $steps * 100" | bc)
    local filled=$(printf "%.0f" $(echo "$percent / 2" | bc))
    local empty=$((50 - filled))
    local bar=$(printf "%${filled}s" | tr ' ' '#')
    bar+=$(printf "%${empty}s" | tr ' ' '-')
    printf "\r[%s] %s%%" "$bar" "$percent"
    sleep $interval
    progress=$((progress + 1))
  done
  echo ""
}

show_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

execute_with_spinner() {
  local command=$1
  echo -n "$2"
  eval "$command" &>/dev/null &
  local pid=$!
  show_spinner $pid
  wait $pid
  echo "Готово!"
}

execute_with_spinner "helm repo add ethereum-helm-charts https://ethpandaops.github.io/ethereum-helm-charts" "Додавання репозиторію ethereum-helm-charts..."
show_progress 2

execute_with_spinner "helm repo update" "Оновлення репозиторіїв Helm..."
show_progress 2

execute_with_spinner "helm install nethermind ethereum-helm-charts/nethermind -f nethermind-values.yaml -n default" "Встановлення Nethermind..."
show_progress 5

execute_with_spinner "helm install lighthouse ethereum-helm-charts/lighthouse -f lighthouse-values.yaml -n default" "Встановлення Lighthouse..."
show_progress 5

execute_with_spinner "helm install prometheus prometheus-community/prometheus" "Встановлення Prometheus..."
show_progress 3

execute_with_spinner "helm install grafana grafana/grafana" "Встановлення Grafana..."
show_progress 3

execute_with_spinner "helm install ethereum-metrics-exporter ethereum-helm-charts/ethereum-metrics-exporter" "Встановлення Ethereum Metrics Exporter..."
show_progress 3

echo "Всі компоненти успішно встановлені!"

