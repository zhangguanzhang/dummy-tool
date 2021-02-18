package main

import (
	"flag"
	"fmt"
	"github.com/zhangguanzhang/dummy-tool/app"
	utilnet "github.com/zhangguanzhang/dummy-tool/pkg/net"
	"log"
	"net"
	"os"
	"runtime"
	"strings"
	"time"
)

var (
	toolApp *app.App

	Version      = "UNKNOWN"
	gitCommit    string
	gitTreeState = ""                     // state of git tree, either "clean" or "dirty"
	buildDate    = "1970-01-01T00:00:00Z" // build date, output of $(date +'%Y-%m-%dT%H:%M:%S')
)

func init() {

	cfg, err := parseAndValidateFlags()
	if err != nil {
		log.Fatalf("Failed to obtain conf instance, err %v", err)
	}
	toolApp = app.NewApp(cfg)
}

func parseAndValidateFlags() (*app.Conf, error) {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprint(os.Stderr, "Runs a tool at initContainer or a Container in kubernetes pod\n")
		flag.PrintDefaults()
	}

	params := &app.Conf{}

	var (
		LocalIPStr string
		versionPrt bool
	)

	flag.StringVar(&LocalIPStr, "localip", "", "comma-separated string of ip addresses to bind localdns process to")
	flag.StringVar(&params.HealthPort, "health-port", "8080", "port used by health plugin, ex: 0.0.0.0:8080")
	flag.BoolVar(&params.SetupInterface, "setupinterface", true, "indicates whether network interface should be setup")
	flag.StringVar(&params.InterfaceName, "interfacename", "nodelocaldns", "name of the interface to be created")
	flag.DurationVar(&params.Interval, "checkinterval", time.Second*5, "interval(in seconds) to check for interface status and addr")
	flag.BoolVar(&versionPrt, "version", false, "print version info and exit")
	flag.Parse()

	versionPrint()

	if versionPrt {
		os.Exit(0)
	}

	for _, ipstr := range strings.Split(LocalIPStr, ",") {
		newIP := net.ParseIP(ipstr)
		if newIP == nil {
			return nil, fmt.Errorf("invalid localip specified - %q", ipstr)
		}
		params.LocalIPs = append(params.LocalIPs, newIP)
	}

	// validate all the IPs have the same IP family
	for _, ip := range params.LocalIPs {
		if utilnet.IsIPv6(params.LocalIPs[0]) != utilnet.IsIPv6(ip) {
			return nil, fmt.Errorf("unexpected IP Family for localIP - %q, want IPv6=%v", ip, utilnet.IsIPv6(params.LocalIPs[0]))
		}
	}

	return params, nil
}

func main() {
	toolApp.Init()
	toolApp.RunApp()
}

func versionPrint() {
	fmt.Printf(`Name: dummy-tool
Version: %s
CommitID: %s
GitTreeState: %s
BuildDate: %s
GoVersion: %s
Compiler: %s
Platform: %s/%s
`, Version, gitCommit, gitTreeState, buildDate, runtime.Version(), runtime.Compiler, runtime.GOOS, runtime.GOARCH)
}
