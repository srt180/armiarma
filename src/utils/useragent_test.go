package utils

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func Test_FilterClientType(t *testing.T) {
	client, version := FilterClientType("teku/teku/v21.8.2/linux-x86_64/corretto-java-16")
	require.Equal(t, client, "Teku")
	require.Equal(t, version, "v21.8.2")

	client, version = FilterClientType("teku/teku/v21.7.0+9-g77b4b9e/linux-x86_64/-ubuntu-openjdk64bitservervm-java-11")
	require.Equal(t, client, "Teku")
	require.Equal(t, version, "v21.7.0")

	client, version = FilterClientType("Prysm/v1.4.3/8bca66ac6408a03af52d65541f58384007ed50ef")
	require.Equal(t, client, "Prysm")
	require.Equal(t, version, "v1.4.3")

	client, version = FilterClientType("Prysm/v1.3.8-hotfix+6c0942/6c09424feb3141b96016bed817d7ade1cd75deb7")
	require.Equal(t, client, "Prysm")
	require.Equal(t, version, "v1.3.8")

	client, version = FilterClientType("Lighthouse/v1.5.1-b0ac346/x86_64-linux")
	require.Equal(t, client, "Lighthouse")
	require.Equal(t, version, "v1.5.1")

	client, version = FilterClientType("Lighthouse/v2.0.0-7c88f58/x86_64-linux")
	require.Equal(t, client, "Lighthouse")
	require.Equal(t, version, "v2.0.0")

	client, version = FilterClientType("nimbus")
	require.Equal(t, client, "Nimbus")
	require.Equal(t, version, "Unknown")

	client, version = FilterClientType("rust-libp2p/0.31.0")
	require.Equal(t, client, "Grandine")
	require.Equal(t, version, "0.31.0")

	client, version = FilterClientType("eth2-crawler")
	require.Equal(t, client, "NodeWatch")
	require.Equal(t, version, "")

	client, version = FilterClientType("go-ipfs/0.8.0/48f94e2")
	require.Equal(t, client, "go-ipgs")
	require.Equal(t, version, "0.8.0")

	client, version = FilterClientType("hydra-booster/0.7.4")
	require.Equal(t, client, "hydra-boost")
	require.Equal(t, version, "0.7.4")

	client, version = FilterClientType("storm")
	require.Equal(t, client, "storm")
	require.Equal(t, version, "Unknown")

	client, version = FilterClientType("lotus-1.13.0+mainnet+git.7a55e8e8")
	require.Equal(t, client, "lotus")
	require.Equal(t, version, "1.13.0")

	client, version = FilterClientType("armiarma-crawler")
	require.Equal(t, client, "BSC-Crawler")
	require.Equal(t, version, "")

	client, version = FilterClientType("bsc-crawler")
	require.Equal(t, client, "BSC-Crawler")
	require.Equal(t, version, "")

	// Check it doesn't break for an unexpected agent
	client, version = FilterClientType("")
	require.Equal(t, client, "NotIdentified")
	require.Equal(t, version, "")
}
