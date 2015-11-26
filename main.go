package main

import (
	"flag"
	"log"
	"strings"
	"time"
)

type View interface {
	PresentState(state *State)
	Close()
}

type Options struct {
	Jobs            []string
	Server          string
	SimpleInterface bool
	Mock            bool
	Refresh         time.Duration
}

var options Options

func init() {
	jobs := flag.String("jobs", "", "CSV of all jobs on the server you want to track")
	server := flag.String("server", "http://jenkins", "URL of the Jenkins server")
	simpleInterface := flag.Bool("simple", false, "Force simple interface (keeps feeding into console)")
	mock := flag.Bool("mock", false, "Use mocked data to see how program behaves")
	refresh := flag.Duration("refresh", 15*time.Second, "How often to refresh Jenkins status")
	flag.Parse()
	options = Options{
		Jobs:            strings.Split(*jobs, ","),
		Server:          *server,
		SimpleInterface: *simpleInterface,
		Mock:            *mock,
		Refresh:         *refresh,
	}
}

func mainLoop(feedbackChannel chan Command, ui *View) {
	var api Api
	if options.Mock {
		api = &MockApi{}
	} else {
		api = &JenkinsApi{
			ServerLocation: options.Server,
		}
	}
	controller := Controller{
		View:      *ui,
		API:       api,
		KnownJobs: options.Jobs,
	}
	ticker := time.NewTicker(options.Refresh)
	firstRun := make(chan bool, 1)
	firstRun <- true
	for {
		select {
		case x := <-feedbackChannel:
			log.Printf("Received: %q\n", x)
			switch x.group {
			case CmdShutdownGroup:
				log.Println("Bye!")
				ticker.Stop()
				return
			case CmdCloseGroup:
				controller.RemoveModals()
			case CmdShowHelpGroup:
				controller.ShowHelp()
			case CmdOpenCurrentJobGroup:
				controller.VisitCurrentJob(x.job)
			case CmdOpenPreviousJobGroup:
				controller.VisitPreviousJob(x.job)
			case CmdTestsForJobGroup:
				controller.ShowTests(x.job)
			}
		case <-ticker.C:
			controller.RefreshNodeInformation()
		case <-firstRun:
			controller.RefreshNodeInformation()
		}
	}
}

func main() {
	var feedbackChannel = make(chan Command)
	var ui View
	var err error
	if options.SimpleInterface {
		ui, err = NewConsoleInterface(feedbackChannel)
	} else {
		ui, err = NewCUIInterface(feedbackChannel)
		if err != nil {
			log.Println("Failure to activate advanced interface", err)
			ui, err = NewConsoleInterface(feedbackChannel)
		}
	}
	if err != nil {
		log.Fatal("Failure to boot interface", err)
	} else {
		mainLoop(feedbackChannel, &ui)
	}
}
