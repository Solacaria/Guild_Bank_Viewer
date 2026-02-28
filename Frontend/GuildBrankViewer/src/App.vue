<template>
  <div class="container">

    <!-- Input box for pasting guild bank data -->
    <div class="inputBox">
      <h2>Paste Guild Bank Data</h2>
      <textarea v-model="pasteString" 
      autofocus="autofocus" 
      resize="none"
      rows="10" cols="50" 
      placeholder="Paste the string of guild bank data here"
      class="inputboxArea" ></textarea>
      <br />
      <button @click="decodeData" button="button">Get data!</button>
    </div>
    
    <!-- Main content area for displaying tables and search -->
    <div class="mainContent">      
      <div class="header">

        <!-- Title and buttons-->
        <div>
          <h1>Guild Bank Logs</h1>
          <div v-if=devMode class="testData">
            <button button="button" @click="testData">Test Data</button>
          </div>
        </div>

        <!-- Search box -->
        <div class="searchBox">
          <div>
            <h2>Search</h2>
            <input v-model="searchTerm" type="text" placeholder="Search by player name..." />
          </div>
          <button @click="searchItem" type="button">Search</button>
        </div>
      </div>
      


      <!-- Item transactions table -->
      <h2>Item Transactions</h2>
      <table border="1" class="itemTable">
        <thead class="headItem">
          <tr class="rowItem">
            <th @click="sortItems('tab')">Tab</th>
            <th @click="sortItems('type')">Type</th>
            <th @click="sortItems('player')">Player</th>
            <th @click="sortItems('item')">Item</th>
            <th @click="sortItems('count')">Count</th>
            <th @click="sortItems('timestamp')">Timestamp</th>
          </tr>
        </thead>
        <tbody class="bodyItem">
          <tr v-for="item in paginatedItems" :key="item.id">
            <td>{{ item.tab }}</td>
            <td>{{ item.type }}</td>
            <td>{{ item.player }}</td>
            <td>{{ item.item }}</td>
            <td>{{ item.count }}</td>
            <td>{{ item.timestamp }}</td>
          </tr>
        </tbody>
      </table>

     <!-- Pagination controls for items -->
      <div>
        <button
          @click="currentPageItems--"
          :disabled="currentPageItems === 1">
          Prev
        </button>
        Page {{ currentPageItems }} of {{ totalPagesItems }}
        <button
          @click="currentPageItems++"
          :disabled="currentPageItems === totalPagesItems">
          Next
        </button>
      </div>

      <!-- Gold transactions table -->
      <h2>Gold Transactions</h2>
      <table border="1" class="goldTable">
        <thead class="headGold">
          <tr class="rowGold">
            <th @click="sortGold('type')">Type</th>
            <th @click="sortGold('player')">Player</th>
            <th @click="sortGold('amount')">Amount</th>
            <th @click="sortGold('timestamp')">Timestamp</th>
          </tr>
        </thead>
        <tbody class="bodyGold">
          <tr v-for="g in paginatedGold" :key="g.id">
            <td>{{ g.type }}</td>
            <td>{{ g.player }}</td>
            <td>{{ g.amount }}</td>
            <td>{{ g.timestamp }}</td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination controls for gold -->
      <div>
        <button
          @click="currentPageGold--"
          :disabled="currentPageGold === 1">
          Prev
        </button>
        Page {{ currentPageGold }} of {{ totalPagesGold }}
        <button
          @click="currentPageGold++"
          :disabled="currentPageGold === totalPagesGold">
          Next
        </button>
      </div>
    </div>   
  </div>
 
    
 
</template>

<script setup>
import { ref, computed } from "vue";
const devMode = false; // Set to true to enable test data button

function getSortedData(dataRef, sortState) {
  return computed(() => {
    if (!sortState.value.key) return dataRef.value;

    return [...dataRef.value].sort((a, b) => {
      const aVal = a[sortState.value.key];
      const bVal = b[sortState.value.key];

      if (aVal < bVal) return sortState.value.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortState.value.direction === 'asc' ? 1 : -1;
      return 0;
    });
  });
}


const pasteString = ref("");
const items = ref([]);
const gold = ref([]);
const searchTerm = ref("");

const sortStateItems = ref({key: "tab", direction: 'asc'});
const sortStateGold = ref({key: "type", direction: 'asc'});

const sortedRowsItems = getSortedData(items, sortStateItems);
const sortedRowsGold = getSortedData(gold, sortStateGold);

//#region Pagination
const currentPageItems = ref(1);
const currentPageGold = ref(1);
const itemsPerPage = 10;

const totalPagesItems = computed(() => {
  return Math.ceil(filteredItems.value.length / itemsPerPage);
});

const totalPagesGold = computed(() => {
  return Math.ceil(filteredGold.value.length / itemsPerPage);
});

const paginatedItems = computed(() => {
  const start = (currentPageItems.value -1) * itemsPerPage;
  const end = start + itemsPerPage;
  return filteredItems.value.slice(start, end);
});

const paginatedGold = computed(() => {
  const start = (currentPageGold.value -1) * itemsPerPage;
  const end = start + itemsPerPage;
  return filteredGold.value.slice(start, end);
});

//#endregion

const decodeData = () => {
  if (!pasteString.value) return;  
  try {
    const json = atob(pasteString.value);
    const data = JSON.parse(json);

    items.value = data.items ? Object.values(data.items).map(i => ({
      ...i,
      item: trimItem(i.item),
      player: trimName(i.player),
      type: decodeType(i.type),
      timestamp: formatTimeAgo(i.time)
    })) : [];


    gold.value = data.gold ? Object.values(data.gold).map(i => ({
      ...i,
      player: trimName(i.player),
      type: decodeType(i.type),
      amount: convertToGold(i.amount),
      timestamp: formatTimeAgo(i.time)
    })) : [];
  }
  catch (error){
    console.error("Failed to decode data:", error);
  }
}

//#region Data formatting functions
const decodeType = (type) => {
  if (type === "d") return "Deposit";
  if (type === "w") return "Withdrawal";
  if (type === "r") return "Repair";
  return type;
}

const trimName = (name) => {
  const nameParts = name.split("-");
  return nameParts[0];
}

const trimItem = (item) => {
  // finds the first [ and captures everything until the first | or ]
  const match = item.match(/\[([^|\]]+)/);
  return match ? match[1] : item;
}

const convertToGold = (amount) => {
  const gold = Math.floor(amount / 10000);
  const restAfterGold = amount % 10000;

  const silver = Math.floor(restAfterGold / 100);
  const copper = restAfterGold % 100;

  return `${gold}g ${silver}s ${copper}c`;
};

const formatTimeAgo = (hoursAgo) => {
  if (hoursAgo < 1) return "Just now";
  if (hoursAgo < 24) return `${Math.floor(hoursAgo)} hours ago`;
  const days = Math.floor(hoursAgo / 24);
  if (days < 30) return `${days} days ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months} months ago`;
  const years = Math.floor(months / 12);
  return `${years} years ago`;
}
//#endregion

const testData = () => {
  const nameList = ["Solacaria", "Aitovo", "Ralkath", "Healmommy", "Kattlåda"];
  const itemList = ["Flask of Alchemical Chaos", "Mycobloom", "Bismuth Ore", "Vantus Rune: Manaforge Omega", "Baa'l"];
  const tabList = ["Gear", "Flask", "Trade goods", "Consumables", "Pets"];

  for (let i = 0; i < 10; i++) {
    items.value.push({
      tab: tabList[Math.floor(Math.random() * tabList.length)],
      type: Math.random() > 0.5 ? "Deposit" : "Withdrawal",
      player: nameList[Math.floor(Math.random() * nameList.length)],
      item: itemList[Math.floor(Math.random() * itemList.length)],
      count: Math.floor(Math.random() * 10) + 1,
      timestamp: Math.floor(Math.random() * 50) + 1 + " hours ago"
    });
    gold.value.push({
      type: Math.random() > 0.5 ? "Deposit" : "Withdrawal",
      player: nameList[Math.floor(Math.random() * nameList.length)],
      amount: Math.floor(Math.random() * 10000) + 100,
      timestamp: new Date().toLocaleString()
    });
  }
}

const sortItems = (table) => {
  if (sortStateItems.value.key === table) {    
    sortStateItems.value.direction = sortStateItems.value.direction === 'asc' ? 'desc' : 'asc';
    currentPageItems.value = 1;
  } else {
    sortStateItems.value.key = table;
    sortStateItems.value.direction = 'asc';
    currentPageItems.value = 1;
  }
}

const sortGold = (table) => {
  if (sortStateGold.value.key === table) {
    sortStateGold.value.direction = sortStateGold.value.direction === 'asc' ? 'desc' : 'asc';
    currentPageGold.value = 1;
  } else {
    sortStateGold.value.key = table;
    sortStateGold.value.direction = 'asc';
    currentPageGold.value = 1;
  }
}

const filteredItems = computed(() => {
  if (!searchTerm.value) return sortedRowsItems.value;

  const term = searchTerm.value.toLowerCase();

  return sortedRowsItems.value.filter(item => 
    item.tab.toLowerCase().includes(term) ||
    item.item.toLowerCase().includes(term) ||
    item.player.toLowerCase().includes(term) ||
    item.type.toLowerCase().includes(term)
  )
})

const filteredGold = computed(() => {
  if (!searchTerm.value) return sortedRowsGold.value;

  const term = searchTerm.value.toLowerCase();

  return sortedRowsGold.value.filter(g => 
    g.player.toLowerCase().includes(term) ||
    g.type.toLowerCase().includes(term)
  )
})

</script>

<style>

.container {
  display: flex;
  flex-direction:row;
  justify-content: center;  
  margin: 0;
  min-height: 100vh;
  background-image: url('/MainBackground.jpg');
  background-size: cover;
  background-position: center;
  background-attachment: fixed;
  background-repeat:repeat;
  color: white;
  
}

.mainContent {
  padding-right: 2rem;
}

.header{
  display: flex;
  align-items: center;
}

table {
  width: 100%;
  table-layout: fixed;
  border-collapse: collapse;
  border: 1px solid white;
  background-color: rgba(0, 0, 0, 0.4);
}

td, th {
  white-space: nowrap;
  overflow: hidden;
  text-overflow:initial;
  padding: 0.75rem 1rem;
  border: 1px solid white;
  color: white;
}

.itemTable th:nth-child(1) { width: 12%; } /* Tab */
.itemTable th:nth-child(2) { width: 15%; } /* Type */
.itemTable th:nth-child(3) { width: 10%; } /* Player */
.itemTable th:nth-child(4) { width: 30%; } /* Item */
.itemTable th:nth-child(5) { width: 8%; }  /* Count */
.itemTable th:nth-child(6) { width: 15%; } /* Timestamp */

.goldTable th:nth-child(1) { width: 25%; } /* Type */
.goldTable th:nth-child(2) { width: 25%; } /* Player */
.goldTable th:nth-child(3) { width: 25%; } /* Amount */
.goldTable th:nth-child(4) { width: 25%; } /* Timestamp */

.inputBox {
  margin-right: 5rem;
  padding-left: 1.5rem;
  
}

.inputboxArea  {
  opacity: 0.5;
  resize: none;
}

.searchBox {
  margin-left: 5rem;
  position:sticky;
}
.headItem th{
  padding: 0.75rem 1.5rem;
}

.headGold th{
  padding: 0.75rem 1.5rem;
}

</style>
