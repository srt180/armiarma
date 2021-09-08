#!/bin/bash
# ------- ARMIARMA --------
# BSC-ETH2 TEAM
# VERSION: v0.0.1
version="v0.0.1"


# ---------- DEFINITION OF FUNTIONS -----------

ARMIARMA="./src/bin/armiarma"
BIN="./src/bin"
VENV="./src/analyzer/venv"
STATIC_DIR="src/analyzer/dashboard/static"

### Help function to show how to run the too
Help()
{
    # Display Help
    echo ""
    echo "  Please make sure the Go version is 1.15 or above."
    echo "  To run armiarma please follow the scheme:"
    echo "      ./armiarma.sh [command] [parameters...]"
    echo "      Commands:"
    echo "          -h      Print this help."
    echo "          -c      Run the crawler on one of the ETH2 networks."
    echo "                  *Parameters for -c [network] [project-name]"
    echo "          -f      Run a time specified test"
    echo "                  *Parameters for -f [network] [project-name] [time](minutes)"
    echo ""
    echo "      Parameters:"
    echo "          [network]       The ETH2 network where the crawler will be running"
    echo "                          Currently supported networks:"
    echo "                              -> mainnet"
    echo "          [project-name]  Specify the name of the folder where the metrics"
    echo "                          and plots will be stored."
    echo "                          Find them on 'armiarma/examples/[project-name]'"
    echo "          [time]          Specific time in minutes to run the crawler, performing afterwards"
    echo "                          the general analysis."
    echo ""
    echo ""
    echo "  BSC-ETH2 TEAM"
}

# Function that calls the crawler
# Arguments (1)->Path of the folder
CompileRumor(){

    # Re-compile Rumor
    echo
    echo "Checking Go dependencies and compiling Rumor ..."
    echo "NOTE: If you are runing Armiarma for first time,"
    echo "      pease note that this might take few minutes."
    cd ./src
    # Check if the ./src/bin folder is already there
    if [[ -d "./bin" ]]; then
        echo "..."
    else
        mkdir bin
    fi
    go build -o ./bin/armiarma
    # Check if the compilation has been successful
    comp_error="$?"
    if [[ "$comp_error" -ne "0" ]]
    then
        echo " Error compiling Rumor"
        exit 1
    else
        echo "Rumor Successfully Compiled!"
    fi
    cd "$1"
    echo
}

# Function that, given the Network and Project-Folder, launches that Armiarma Crawler
# Generating folders and Compiling Rumor
# Arguments -> (1)-> Network Name (2)-> Path of the folder (3)-> Folder Path (4)-> Running Time (5)->Compile Rumor
LaunchCrawler(){
    networkName="$1"
    folderName="$2"
    folderPath="$3"
    # Flag to see if rumor needs to be installed/called
    rumorFlag="0"
    executableNetwork=""

    echo
    echo "  Crawler selected"
    echo
    echo "  network:        $networkName"
    echo "  metrics-folder: $folderName"
    echo

    # Check if the given project path was empty
    if [[ -z  "$2" ]]; then
        echo "Error. No project-name was given." >&2
        echo "Please check the '-h' command to display the Help menu" >&2
        exit 1
    fi


    # Check the given network
    if [[ "$networkName" == "mainnet" ]]
    then
        echo "Mainnet network selected"
        # source the config file for the Eth2 Mainnet network
        source ./networks/mainnet/config.sh
        rumorFlag=$((rumorFlag+1))
        executableNetwork="mainnet-launcher.rumor"
    else
        echo "Invalid newtork."
        echo "Available networks:"
        echo "  -> mainnet"
        exit 1
    fi

    # Check if rumor flag has been activated to Run/compiled Rumor
    if [[ $rumorFlag -eq 1 ]]
    then
        # Rumor would need to be run/compiled
        CompileRumor "$folderPath"

        # Switch to the crawler folder where the ".rumor" files are located
        #cd ./src/crawler

        # Generate the full-path for the metrics folder
        metricsFolder="${folderPath}/examples/${folderName}"

        # Check if the directory already exists
        if [[ -d $metricsFolder ]]; then
            echo
            echo "Project with name $folderName already exist" >&2
            echo "Loading Project"
            echo
            cd $metricsFolder
        else
            echo "Getting the env ready"
            mkdir $metricsFolder

            # Make a temporary copy of the config.sh file on the new folder
            echo "Generating the config.sh"
            cp "./networks/${networkName}/config.sh" "./examples/${folderName}"

            # Move to the example folder
            cd "./examples/${folderName}"

            # Append the bash env variables to the temp fhiustile
            echo "metricsFolder=\"${metricsFolder}\"" >> config.sh
            echo "armiarmaPath=\"${folderPath}\"" >> config.sh

            if [[ -z  "$4" ]]
            then
                echo "time range has not been assigned"
            else
                timeRange="$4"
                echo "Time range: $timeRange mins"
                echo "timeRange=\"${timeRange}\"" >> config.sh
            fi

            cd $metricsFolder
            TouchLauncher "$folderName"
        fi

        cd $metricsFolder

        echo ""
        echo "Executing file $executableNetwork"
        echo "Exporting metrics at $metricsFolder"
        echo ""

        # Finaly launch Rumor form the Network File (showing the logs on terminal mode)
        sh -c 'echo "PID of the crawler: $$"; echo ""; exec ../../src/bin/armiarma file launcher.rumor --formatter="terminal" --level="error"'
        # Check if the compilation has been successful
        exec_error="$?"
        if [[ "$exec_error" -ne "0" ]]
        then
            echo " Error, somethign went wrong, Exit status $exec_error"
            exit 1
        else
            echo "Armiarma Successfully Worked!"
        fi
    fi

}

# Generate a plain launcher.rumor on the current PATH
# Receives (1)-> Example folder (2) -> Folder Path
TouchLauncher(){
    echo "Generating $1 Rumor Launcher"
    touch launcher.rumor
    echo "# $1 launcher" >> launcher.rumor
    echo "source config.sh" >> launcher.rumor
    echo "" >> launcher.rumor
    echo "# cd to the crawler directory" >> launcher.rumor
    echo "cd ../../src/crawler" >> launcher.rumor
    echo "# Launch the crawler" >> launcher.rumor
    echo "include crawler.rumor" >> launcher.rumor
}

# Function that, given the Project-Folder, launches that Armiarma CrawAnalyzer
# Generating python venv and the output graphs/plots
# Arguments -> (1)-> Path of the folder
LaunchAnalyzer(){
    aux="$1"
    folderPath="$2"

    echo ""
    echo " Folder to be analyzed: $aux"
    echo ""

    # Check if the virtual environment has been created
    if [[ -d $VENV ]]; then
        echo "venv already created"
    else
        echo "Generating the virtual env"
        python3 -m virtualenv "$VENV"
    fi
    echo ""
    # Source the virtual env
    source "${VENV}/bin/activate"

    # ---- TEMP ----
    # Check if the virtual env is created
    venvPath="${PWD}/src/analyzer/venv"
    if [[ "$VIRTUAL_ENV" = "$venvPath" ]]
    then
        echo "VENV successfuly sourced"
    else
        echo "ERROR. VENV was unable to source" >&2
    fi
    echo ""
    # -- END TEMP --

    echo "Checking if Python dependencies are installed..."
    pip3 install -r ./src/analyzer/requirements.txt
    echo ""

    # Set the Paths for the gossip-metrics.json peerstore.json and output
    csv="${folderPath}/examples/${aux}/metrics.csv"
    peerstore="${folderPath}/examples/${aux}/peerstore.json"
    plots="${folderPath}/examples/${aux}/plots"


    if [[ -d $plots ]]; then
        echo ""
    else
        mkdir "examples/${aux}/plots"
    fi

    # Run the Analyzer
    echo "  Launching analyzer"
    echo ""
    python3 ./src/analyzer/armiarma-analyzer.py "$csv" "$peerstore" "$plots"

    # Deactivate the VENV
    deactivate

}

# -------- END OF FUNCTION DEFINITION ---------

# Execution Secuence

# 0. Get the options
go version
pid="$!"
echo "PID: $pid"

# Generate the examples folder
if [[ -d ./examples ]]; then
    echo ""
    echo "  ----------- ARMIARMA $version -----------"
else
    echo ""
    echo "  ----------- ARMIARMA $version -----------"
    echo ""
    echo "Generating ./examples folder"
    echo ""
    mkdir ./examples
fi
# Generate the general-results folder
if [[ -d ./general-results ]]; then
    echo ""
else
    echo ""
    echo "Generating ./general-results folder"
    echo ""
    mkdir ./general-results
fi

# Check if any argument was given.
# If not, print Help and exit
if [[ -z "$1" ]]; then
    echo "Error. No arguments were given." >&2
    echo "Please check the '-h' command to display the Help menu" >&2
    exit 1
fi

while getopts ":hcpfdo" option; do
    case $option in
        h)  # display Help
            Help
            exit;;
        c)  # execute rumor (if its compiled)
            # Save [name]

            LaunchCrawler "$2" "$3" "$PWD"

            echo "Armiarma Finished!"
            exit;;

        f) # Option to run Armiarma Crawler for a specific given time, processing the results with the Analyzer
            networkName="$2"
            folderName="$3"
            runningTime="$4" #Minutes
            folderPath="$PWD"

            echo "INFO: The crawler will be up for $runningTime m"
            echo ""

            # Check if the given project path was empty
            if [[ -z  "$4" ]]; then
                echo "Error. No running time range was given." >&2
                echo "Please check the '-h' command to display the Help menu" >&2
                exit 1
            fi

            echo "Calling the Crawler"
            LaunchCrawler "$networkName" "$folderName" "$folderPath" "$runningTime"

            echo "Exit Crawler execution"
            exit;;

        \?) # incorrect option
            echo "Invalid option"
            echo
            Help
            exit;;
    esac
done

echo ""
exit 0
