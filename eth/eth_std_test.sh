#!/bin/sh

# Function to run a command and return its output
run_command() {
    result=$(eval "$1" 2>&1)
    echo "$result"
}

# Function to enable the Ethernet interface using standard Linux commands
enable_eth_interface() {
    local iface=$1
    echo "Enabling Ethernet interface $iface..."
    result=$(run_command "ip link set dev $iface up")
    if [ $? -ne 0 ]; then
        echo "Failed to enable Ethernet interface $iface: $result"
        return 1
    fi
    echo "Ethernet interface $iface enabled."
    return 0
}

# Function to configure the network settings for the Ethernet interface
configure_network() {
    local iface=$1
    echo "Configuring network for Ethernet interface $iface..."
    # Assuming DHCP configuration
    result=$(run_command "dhclient $iface")
    if [ $? -ne 0 ]; then
        echo "Failed to configure network for $iface: $result"
        return 1
    fi
    echo "Network configured for Ethernet interface $iface."
    return 0
}

# Function to check the connection status using standard Linux commands
check_connection_status() {
    local iface=$1
    echo "Checking connection status for $iface..."
    operstate=$(run_command "cat /sys/class/net/$iface/operstate")
    carrier=$(run_command "cat /sys/class/net/$iface/carrier")

    echo "Interface $iface operational state: $operstate"
    echo "Interface $iface carrier: $carrier"

    if [ "$operstate" = "up" ] && [ "$carrier" -eq 1 ]; then
        return 0
    fi
    return 1
}

# Function to perform a basic connectivity test
perform_connectivity_test() {
    echo "Performing connectivity test..."
    result=$(run_command "ping -c 4 8.8.8.8")
    if echo "$result" | grep -q "0% packet loss"; then
        echo "Connectivity test passed."
        return 0
    fi
    echo "Connectivity test failed."
    return 1
}

# Main script execution
main() {
    local iface="eth0" # Change this to your Ethernet interface name

    # Step 1: Enable the Ethernet interface
    enable_eth_interface $iface
    if [ $? -ne 0 ]; then
        echo "Ethernet interface enable failed."
        exit 1
    fi
    sleep 5

    # Step 2: Configure the network settings
    configure_network $iface
    if [ $? -ne 0 ]; then
        echo "Network configuration failed."
        exit 1
    fi
    sleep 5

    # Step 3: Check the connection status
    check_connection_status $iface
    if [ $? -ne 0 ]; then
        echo "Connection status check failed."
        exit 1
    fi

    # Step 4: Perform a connectivity test
    perform_connectivity_test
    if [ $? -ne 0 ]; then
        echo "Connectivity test failed."
        exit 1
    fi

    echo "Network functionality test passed."
}

# Run the main function
main
