package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"strconv"
)

type Data struct {
	Message string `json:"message"`
}

var (
	// Version is the version of the application. This can be set during build time.
	Version = "dev"

	// Commit is the commit hash of the application. This can be set during build time.
	Commit = "none"

	// Date is the build date of the application. This can be set during build time.
	Date = "unknown"
)

func printVersion() {
	fmt.Printf("Version: %s\n", Version)
	fmt.Printf("Commit: %s\n", Commit)
	fmt.Printf("Date: %s\n", Date)
}

func main() {
	printVersionFlag := flag.Bool("version", false, "Specifies if the tool needs to print the version and exit.")
	flag.Parse()

	if *printVersionFlag {
		printVersion()
		os.Exit(0)
	}

	port := os.Getenv("PORT")
	portNumber, err := strconv.Atoi(port)
	log.Printf("PORT env var is: %s\n", port)
	if err != nil || portNumber < 1000 || portNumber > 65535 {
		port = "8080"
	}

	http.HandleFunc("/", serveTemplate)
	http.HandleFunc("/data", serveData)
	http.HandleFunc("/version", showVersion)

	log.Printf("Starting server on: %s\n", port)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

func serveTemplate(w http.ResponseWriter, r *http.Request) {
	tmpl := template.Must(template.ParseFiles("templates/index.html"))
	err := tmpl.Execute(w, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func serveData(w http.ResponseWriter, r *http.Request) {
	data := Data{
		Message: "Hello from the Go endpoint!",
	}
	w.Header().Set("Content-Type", "application/json")
	err := json.NewEncoder(w).Encode(data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func showVersion(w http.ResponseWriter, r *http.Request) {
	data := Data{
		Message: Version,
	}
	w.Header().Set("Content-Type", "application/json")
	err := json.NewEncoder(w).Encode(data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}
