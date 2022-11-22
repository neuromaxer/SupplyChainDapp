import SupplyChainArtifact from "../build/contracts/SupplyChain.json" assert { type: "json" };

const App = {
    web3Provider: null,
    web3: null,
    upc: 0,
    metamaskAccountID: "0x0000000000000000000000000000000000000000",
    ownerID: "0x0000000000000000000000000000000000000000",
    originFarmerID: "0x0000000000000000000000000000000000000000",
    originFarmName: null,
    originFarmInformation: null,
    originFarmLatitude: null,
    originFarmLongitude: null,
    productNotes: null,
    sellPrice: 0,
    buyPrice: 0,
    distributorID: "0x0000000000000000000000000000000000000000",
    retailerID: "0x0000000000000000000000000000000000000000",
    consumerID: "0x0000000000000000000000000000000000000000",
    currentAccount: null,

    init: async function () {
        App.readForm();
        /// Setup access to blockchain
        return await App.initWeb3();
    },

    readForm: function () {
        App.upc = parseInt($("#upc").val());
        App.ownerID = $("#ownerID").val();
        App.originFarmerID = $("#originFarmerID").val();
        App.originFarmName = $("#originFarmName").val();
        App.originFarmInformation = $("#originFarmInformation").val();
        App.originFarmLatitude = $("#originFarmLatitude").val();
        App.originFarmLongitude = $("#originFarmLongitude").val();
        App.productNotes = $("#productNotes").val();
        App.sellPrice = $("#sellPrice").val();
        App.buyPrice = $("#buyPrice").val();
        App.distributorID = $("#distributorID").val();
        App.retailerID = $("#retailerID").val();
        App.consumerID = $("#consumerID").val();
        App.upcToFetch = $("#upcToFetch").val();
    },

    initWeb3: async function () {
        /// Find or Inject Web3 Provider
        if (window.ethereum) {
            App.web3 = new Web3(window.ethereum);
            let accounts = await App.web3.eth.requestAccounts();
            console.log(
                "Using Metamask as Web3 provider. Accounts: \n",
                accounts
            );
        }
        // If no injected web3 instance is detected, fall back to Ganache
        else {
            console.warn(
                "No web3 detected. Falling back to HTTP://127.0.0.1:7545. Remove this fallback when deploying live"
            );
            App.web3 = new Web3(
                new Web3.providers.HttpProvider("http://localhost:7545")
            );
        }

        await App.getCurrentAccountID();
        await App.initContract();
        await App.fetchPastEvents();
        App.subscribeToEvents();
        return App.bindEvents();
    },

    getCurrentAccountID: async function () {
        try {
            const accounts = await App.web3.eth.getAccounts();
            App.currentAccount = accounts[0];
            console.log(`Current account is ${App.currentAccount}`);
        } catch (error) {
            console.error("Could not getMetamaskAccountID");
        }
    },

    initContract: async function () {
        const { web3 } = this;

        try {
            const networkId = await web3.eth.net.getId();
            const deployedNetwork = SupplyChainArtifact.networks[networkId];
            this.supplyChainContract = new web3.eth.Contract(
                SupplyChainArtifact.abi,
                deployedNetwork.address
            );
        } catch (error) {
            console.error("Could not initialize the supplyChainContract");
            console.log("Error: ", error);
        }
    },

    assignRole: async function () {
        // Assign role to a specified address
        App.getCurrentAccountID();
        let role = $("#rolesDropdown").val();
        let address = $("#addressToAssignRole").val();
        let { addFarmer, addDistributor, addRetailer, addConsumer } =
            this.supplyChainContract.methods;

        if (role == "Farmer") {
            await addFarmer(address).send({ from: this.currentAccount });
        } else if (role == "Distributor") {
            await addDistributor(address).send({ from: this.currentAccount });
        } else if (role == "Retailer") {
            await addRetailer(address).send({ from: this.currentAccount });
        } else if (role == "Consumer") {
            await addConsumer(address).send({ from: this.currentAccount });
        } else {
            console.log(`Role ${role} cannot be assigned`);
        }

        console.log(`Role ${role} is assigned to address ${address}`);
    },

    bindEvents: function () {
        $(document).on("click", App.handleButtonClick);
    },

    handleButtonClick: async function (event) {
        event.preventDefault();

        var processId = parseInt($(event.target).data("id"));

        switch (processId) {
            case 1:
                return await App.harvestItem(event);
                break;
            case 2:
                return await App.processItem(event);
                break;
            case 3:
                return await App.packItem(event);
                break;
            case 4:
                return await App.sellItem(event);
                break;
            case 5:
                return await App.buyItem(event);
                break;
            case 6:
                return await App.shipItem(event);
                break;
            case 7:
                return await App.receiveItem(event);
                break;
            case 8:
                return await App.purchaseItem(event);
                break;
            case 9:
                return await App.fetchItemBufferOne(event);
                break;
            case 10:
                return await App.fetchItemBufferTwo(event);
                break;
            default:
                break;
        }
    },

    refreshData: async function () {
        await App.getCurrentAccountID();
        App.readForm();
    },

    harvestItem: async function (event) {
        await App.refreshData();
        let { harvestItem } = App.supplyChainContract.methods;

        harvestItem(
            App.upc,
            App.originFarmName,
            App.originFarmInformation,
            App.originFarmLatitude,
            App.originFarmLongitude,
            App.productNotes
        ).send({ from: this.currentAccount });
    },

    processItem: async function (event) {
        await App.refreshData();
        let { processItem } = App.supplyChainContract.methods;

        processItem(App.upc).send({ from: this.currentAccount });
    },

    packItem: async function (event) {
        await App.refreshData();
        let { packItem } = App.supplyChainContract.methods;

        packItem(App.upc).send({ from: this.currentAccount });
    },

    sellItem: async function (event) {
        await App.refreshData();
        let { sellItem } = App.supplyChainContract.methods;

        sellItem(App.upc, App.sellPrice).send({
            from: App.currentAccount,
        });
    },

    buyItem: async function (event) {
        await App.refreshData();
        let { buyItem } = App.supplyChainContract.methods;

        buyItem(App.upc).send({
            from: this.currentAccount,
            value: App.buyPrice,
        });
    },

    shipItem: async function (event) {
        await App.refreshData();
        let { shipItem } = App.supplyChainContract.methods;

        shipItem(App.upc).send({ from: this.currentAccount });
    },

    receiveItem: async function (event) {
        await App.refreshData();
        let { receiveItem } = App.supplyChainContract.methods;

        receiveItem(App.upc).send({ from: this.currentAccount });
    },

    purchaseItem: async function (event) {
        await App.refreshData();
        let { purchaseItem } = App.supplyChainContract.methods;

        purchaseItem(App.upc).send({ from: this.currentAccount });
    },

    fetchItemBufferOne: async function () {
        await App.getCurrentAccountID();
        App.readForm();

        let { fetchItemBufferOne } = App.supplyChainContract.methods;
        let bufferOne = await fetchItemBufferOne(App.upc).call();
        $("#buffer-type").text(" Buffer 1");
        App.displayItemData(bufferOne);
    },

    fetchItemBufferTwo: async function () {
        await App.getCurrentAccountID();
        App.readForm();

        let { fetchItemBufferTwo } = App.supplyChainContract.methods;
        let bufferTwo = await fetchItemBufferTwo(App.upc).call();
        $("#buffer-type").text(" Buffer 2");
        App.displayItemData(bufferTwo);
    },

    displayItemData: function (buffer) {
        $("#item-data").empty();
        for (const [key, value] of Object.entries(buffer)) {
            if (isNaN(key)) {
                $("#item-data").append("<li>" + key + ": " + value + "</li>");
            }
        }
    },

    fetchPastEvents: async function () {
        console.log("Trying to fetch past events...");
        $("#ftc-events").empty();
        await App.supplyChainContract
            .getPastEvents("allEvents", { fromBlock: 1 })
            .then(function (events) {
                for (const event of events) {
                    $("#ftc-events").append(
                        "<li>" +
                            event.event +
                            " - " +
                            event.transactionHash +
                            "</li>"
                    );
                }
            })
            .catch(console.log);
    },
    subscribeToEvents: function () {
        App.supplyChainContract.events
            .allEvents(console.log)
            .on("data", function (event) {
                console.log(event);
                $("#ftc-events").append(
                    "<li>" +
                        event.event +
                        " - " +
                        event.transactionHash +
                        "</li>"
                );
            });
    },
};

window.App = App;
