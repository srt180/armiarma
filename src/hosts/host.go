package hosts

import (
	"context"
	"fmt"

	noise "github.com/libp2p/go-libp2p-noise"
	tcp_transport "github.com/libp2p/go-tcp-transport"
	"github.com/migalabs/armiarma/src/base"
	"github.com/migalabs/armiarma/src/db"
	"github.com/migalabs/armiarma/src/info"
	"github.com/migalabs/armiarma/src/utils/apis"

	libp2p "github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p-core/host"
	"github.com/libp2p/go-libp2p-core/peer"
	"github.com/libp2p/go-libp2p/p2p/protocol/identify"

	ma "github.com/multiformats/go-multiaddr"
)

var (
	ModuleName       = "LIBP2P_HOST"
	ConnNotChannSize = 400
)

// Struct that defines the Basic Struct asociated to the Libtp2p host
type BasicLibp2pHost struct {
	*base.Base
	// Basic sevices related with the libp2p host
	host      host.Host
	identify  *identify.IDService
	PeerStore *db.PeerStore
	IpLocator *apis.PeerLocalizer

	// Basic Host Metadata
	info_obj      *info.InfoData
	multiAddr     ma.Multiaddr
	fullMultiAddr ma.Multiaddr

	connEventNotChannel chan ConnectionEvent
	peerID              peer.ID
}

type BasicLibp2pHostOpts struct {
	Info_obj  info.InfoData
	IpLocator *apis.PeerLocalizer
	LogOpts   base.LogOpts
	PeerStore *db.PeerStore
	// TODO: -Add IdService for the libp2p host
}

// Generate a new Libp2p host from the given context and Options
// TODO: missing argument for app info (givin Privkeys, IPs, ports, userAgents)
func NewBasicLibp2pHost(ctx context.Context, opts BasicLibp2pHostOpts) (*BasicLibp2pHost, error) {
	// Generate Base module struct with basic funtioning
	//opts.LogOpts.Level = "debug"
	b, err := base.NewBase(
		base.WithContext(ctx),
		base.WithLogger(base.LogOpts{
			ModName:   opts.LogOpts.ModName,
			Output:    opts.LogOpts.Output,
			Formatter: opts.LogOpts.Formatter,
			Level:     opts.LogOpts.Level,
		}),
	)
	if err != nil {
		return nil, fmt.Errorf("couldn't create base for host module. %s", err)
	}
	// check the parsed host options

	ip := opts.Info_obj.GetIPToString()
	tcp := opts.Info_obj.GetTcpPortString()
	privkey := opts.Info_obj.GetPrivKey()
	userAgent := opts.Info_obj.GetUserAgent()

	// generate de multiaddress
	multiaddr := fmt.Sprintf("/ip4/%s/tcp/%s", ip, tcp)
	muladdr, err := ma.NewMultiaddr(multiaddr)
	if err != nil {
		b.Log.Debugf("couldn't generate multiaddress from ip %s and tcp %s", ip, tcp)
		multiaddr = fmt.Sprintf("/ip4/%s/tcp/%s", DefaultIP, DefaultTCP)
		muladdr, _ = ma.NewMultiaddr(multiaddr)
	}
	b.Log.Debugf("setting multiaddress to %s", muladdr)

	// Generate the main Libp2p host that will be exposed to the network
	host, err := libp2p.New(
		b.Ctx(),
		libp2p.ListenAddrs(muladdr),
		libp2p.Identity(privkey),
		libp2p.UserAgent(opts.Info_obj.GetUserAgent()),
		libp2p.Transport(tcp_transport.NewTCPTransport),
		libp2p.Security(noise.ID, noise.New),
		libp2p.NATPortMap(),
	)
	if err != nil {
		return nil, err
	}
	peerId := host.ID().String()
	fmaddr := host.Addrs()[0].String() + "/p2p/" + host.ID().String()
	localMultiaddr, _ := ma.NewMultiaddr(fmaddr)
	b.Log.Debugf("full multiaddress %s", localMultiaddr)
	// generate the identify service
	ids, err := identify.NewIDService(host, identify.UserAgent(userAgent), identify.DisableSignedPeerRecord())
	if err != nil {
		return nil, err
	}
	// Gererate the struct that contains all the configuration and structs surrounding the Libp2p Host
	basicHost := &BasicLibp2pHost{
		Base:                b,
		host:                host,
		identify:            ids,
		PeerStore:           opts.PeerStore,
		IpLocator:           opts.IpLocator,
		info_obj:            &opts.Info_obj,
		multiAddr:           muladdr,
		fullMultiAddr:       localMultiaddr,
		peerID:              peer.ID(peerId),
		connEventNotChannel: make(chan ConnectionEvent, ConnNotChannSize),
	}
	b.Log.Debug("setting custom notification functions")
	basicHost.SetCustomNotifications()

	return basicHost, nil
}

// return the libp2p host from the host Module
func (b *BasicLibp2pHost) Host() host.Host {
	return b.host
}

// start the libp2pHost module (perhaps NOT NECESARY)
// So far, start listening on the fullMultiAddrs
func (b *BasicLibp2pHost) Start() {
	err := b.host.Network().Listen()
	if err != nil {
		b.Log.Errorf("error starting. %s", err)
	} else {
		b.Log.Infof("libp2p host module started")
	}
}

// cancel the context of the libp2pHost module
func (b *BasicLibp2pHost) Stop() {
	b.Log.Info("stopping Libp2p host")
	b.Cancel()
}

func (b *BasicLibp2pHost) RecConnEvent(connEvent ConnectionEvent) {
	b.connEventNotChannel <- connEvent
}

func (b *BasicLibp2pHost) ConnEventNotChannel() chan ConnectionEvent {
	return b.connEventNotChannel
}

func (b *BasicLibp2pHost) GetInfoObj() *info.InfoData {
	return b.info_obj
}
