package app

import (
	"context"
	"fmt"
	"github.com/zhangguanzhang/dummy-tool/pkg/netif"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"time"
)

type Conf struct {
	LocalIPs       []net.IP      // parsed ip addresses for the local cache agent to listen for dns requests
	SetupInterface bool          // Indicates whether to setup network interface
	InterfaceName  string        // Name of the interface to be created
	Interval       time.Duration // specifies how often to run iptables rules check
	HealthPort     string        // port for the healthcheck
	netifHandle    *netif.NetifManager
}

type App struct {
	params      *Conf
	netifHandle *netif.NetifManager
	exitChan    chan struct{} // Channel to terminate background goroutines
}

// NewApp returns a new instance of App by applying the specified config params.
func NewApp(params *Conf) *App {
	return &App{params: params}
}

func (c *App) Init() {
	if c.params.SetupInterface {
		c.netifHandle = netif.NewNetifManager(c.params.LocalIPs)
	}
	if c.params.HealthPort != "" && !strings.Contains(c.params.HealthPort, ":") {
		c.params.HealthPort = ":" + c.params.HealthPort
	}
}

func (c *App) RunApp() {

	var srvShutdown func(ctx context.Context) error

	c.setupNetworking()
	// if not set Interval, will use for a intContianer just setup and exit
	if c.params.Interval != 0 {
		go c.runPeriodic()

		if c.params.HealthPort != "" {
			srvShutdown = c.healthCheck()
		}

		sigCh := make(chan os.Signal)
		signal.Notify(sigCh)
		s := <-sigCh
		// Unlikely to reach here, if we did it is because coremain exited and the signal was not trapped.
		log.Printf("[INFO] Received signal: %s, tearing down", s.String())

		if srvShutdown != nil {
			ctx, cancel := context.WithTimeout(context.Background(), time.Second)
			defer cancel()
			_ = srvShutdown(ctx)
		}

		if err := c.TeardownNetworking(); err != nil {
			log.Printf("[ERROR] While TeardownNetworking: %v", err)
		}
	}
}

func (c *App) runPeriodic() {
	c.exitChan = make(chan struct{}, 1)
	tick := time.NewTicker(c.params.Interval * time.Second)
	for {
		select {
		case <-tick.C:
			c.setupNetworking()
		case <-c.exitChan:
			log.Printf("[WARNING] Exiting check interface")
			return
		}
	}
}

func (c *App) setupNetworking() {
	if c.params.SetupInterface {
		exists, err := c.netifHandle.EnsureDummyDevice(c.params.InterfaceName)
		if !exists {
			if err != nil {
				log.Printf("[ERROR] Failed to add non-existent interface %s: %s", c.params.InterfaceName, err)
			}
			log.Printf("[INFO] Added interface - %s", c.params.InterfaceName)
		}
		if err != nil {
			log.Printf("[ERROR] Error checking dummy device %s - %s", c.params.InterfaceName, err)
		}
	}
}

func (c *App) TeardownNetworking() error {
	log.Printf("[INFO] Tearing down")
	if c.exitChan != nil {
		// Stop the goroutine that periodically checks for iptables rules/dummy interface
		// exitChan is a buffered channel of size 1, so this will not block
		c.exitChan <- struct{}{}
	}
	var err error
	if c.params.SetupInterface {
		err = c.netifHandle.RemoveDummyDevice(c.params.InterfaceName)
	}

	return err
}

func (c *App) healthCheck() func(ctx context.Context) error {

	mux := http.NewServeMux()
	mux.Handle("/health", http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "ok")
		},
	))
	srv := &http.Server{
		Addr:    c.params.HealthPort,
		Handler: mux,
	}
	go func() {
		log.Printf("[INFO] Start http health at %s", c.params.HealthPort)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	return srv.Shutdown
}