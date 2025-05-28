
let dashboardData = {
    totalEmployees: 485,
    grossSalary: 7482.10,
    netPay: 2485,
    overallSales: 1896,
    overallSalesByDay: [35, 25, 50, 40, 60, 45, 65, 30],
    recentOrders: [
        {
            customer: "Sarah Johnson",
            product: "Premium Package",
            status: "processing",
            amount: 299.00,
            avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29160?w=32&h=32&fit=crop&crop=face"
        },
        {
            customer: "Mike Chen",
            product: "Basic Plan",
            status: "completed",
            amount: 99.00,
            avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=32&h=32&fit=crop&crop=face"
        },
        {
            customer: "Emma Davis",
            product: "Enterprise Suite",
            status: "pending",
            amount: 599.00,
            avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=32&h=32&fit=crop&crop=face"
        },
        // Added more orders to make the table longer
        {
            customer: "David Wilson",
            product: "Standard Package",
            status: "completed",
            amount: 199.00,
            avatar: "https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=32&h=32&fit=crop&crop=face"
        },
        {
            customer: "Linda Taylor",
            product: "Add-on Module A",
            status: "processing",
            amount: 79.50,
            avatar: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=32&h=32&fit=crop&crop=face"
        },
         {
            customer: "James Brown",
            product: "Consultation Hour",
            status: "completed",
            amount: 150.00,
            avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=32&h=32&fit=crop&crop=face"
        }
    ],    recentActivity: [
        {
            icon: "fas fa-user-plus",
            text: "New employee John Doe joined Design team",
            time: "2 hours ago"
        },
        {
            icon: "fas fa-shopping-cart",
            text: "Order #1234 completed successfully",
            time: "4 hours ago"
        },
        {
            icon: "fas fa-tasks",
            text: "Project Alpha moved to review stage",
            time: "6 hours ago"
        },
        {
            icon: "fas fa-bell",
            text: "System maintenance scheduled",
            time: "1 day ago"
        },
        {
            icon: "fas fa-money-bill-transfer",
            text: "Payroll for March processed",
            time: "2 days ago"
        }
    ]
};

function getCurrentDate() {
    const now = new Date();
    const options = { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
    };
    return now.toLocaleDateString('en-US', options);
}

function toggleSearch() {
    const searchBar = document.getElementById('searchBar');
    const searchInput = document.getElementById('searchInput');
    searchBar.classList.toggle('expanded');
    if (searchBar.classList.contains('expanded')) {
        setTimeout(() => { searchInput.focus(); }, 300);
    } else {
        searchInput.blur();
    }
}

document.addEventListener('click', function(event) {
    const searchContainer = document.querySelector('.search-container');
    if (!searchContainer.contains(event.target) && !document.getElementById('searchBar').contains(event.target)) {
        document.getElementById('searchBar').classList.remove('expanded');
    }
});

function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('mobile-visible');
    document.getElementById('mainContent').classList.toggle('expanded');
}

document.addEventListener('click', function(event) {
    const sidebar = document.getElementById('sidebar');
    const menuBtn = document.querySelector('.mobile-menu-btn');
    if (window.innerWidth <= 768 && sidebar.classList.contains('mobile-visible') &&
        !sidebar.contains(event.target) && !menuBtn.contains(event.target)) {
        sidebar.classList.remove('mobile-visible');
        document.getElementById('mainContent').classList.remove('expanded');
    }
});

function initializeDashboard() {
    updateCurrentDate();
    updateStatsCards();
    createOverallSalesChart(); // Renamed function
    // updateProjectOverview(); // Commented out as Project Overview card content is replaced
    populateRecentOrders();
    populateRecentActivity(); // This will now populate the list in its new location
}

function updateCurrentDate() {
    document.getElementById('currentDate').textContent = getCurrentDate();
}

function updateStatsCards() {
    document.getElementById('totalEmployees').textContent = dashboardData.totalEmployees;    document.getElementById('grossSalary').textContent = `₱ ${dashboardData.grossSalary.toLocaleString()}`;
    document.getElementById('netPay').textContent = `₱ ${dashboardData.netPay.toLocaleString()}`;
    document.getElementById('overallSalesValue').textContent = `₱ ${dashboardData.overallSales.toLocaleString()}`; // Updated ID
}

function createOverallSalesChart() { // Renamed from createJobAppliedChart
    const chartContainer = document.getElementById('overallSalesChart'); // Updated ID
    chartContainer.innerHTML = '';
    
    const maxValue = Math.max(...dashboardData.overallSalesByDay); // Using new data
    
    dashboardData.overallSalesByDay.forEach((value, index) => { // Using new data
        const bar = document.createElement('div');
        bar.className = 'bar';
        bar.style.height = `${(value / maxValue) * 100}%`;
        if (index === 4) { bar.classList.add('active'); } // Example active bar
        chartContainer.appendChild(bar);
    });
}

// function updateProjectOverview() { ... } // This function is no longer directly rendering to the main UI in that card.

function populateRecentOrders() {
    const tbody = document.getElementById('ordersTableBody'); // Updated ID
    tbody.innerHTML = '';
    
    dashboardData.recentOrders.forEach(order => {
        const statusClass = order.status.toLowerCase();
        const statusText = order.status.charAt(0).toUpperCase() + order.status.slice(1);
        
        const row = document.createElement('tr');
        row.className = 'order-row'; // Class name updated
        row.innerHTML = `
            <td>
                <div class="customer-name"> <!-- Class name updated -->
                    <img src="${order.avatar}" alt="${order.customer}" class="customer-avatar"> <!-- Class name updated -->
                    ${order.customer}
                </div>
            </td>
            <td>${order.product}</td>
            <td><span class="status-badge ${statusClass}">${statusText}</span></td>
            <td>$${order.amount.toFixed(2)}</td> <!-- Added $ sign -->
        `;
        tbody.appendChild(row);
    });
}

function populateRecentActivity() {
    const activityList = document.getElementById('activityList'); // ID is the same, but element is moved
    activityList.innerHTML = ''; // Clear existing, if any
    
    dashboardData.recentActivity.forEach(activity => {
        const activityItem = document.createElement('div');
        activityItem.className = 'activity-item';
        activityItem.innerHTML = `
            <div class="activity-icon">
                <i class="${activity.icon}"></i>
            </div>
            <div class="activity-content">
                <div class="activity-text">${activity.text}</div>
                <div class="activity-time">${activity.time}</div>
            </div>
        `;
        activityList.appendChild(activityItem);
    });
}

function connectToFirestore() {
    // Placeholder for actual Firestore connection
    // For demo, simulate some data changes
    setInterval(() => {
        dashboardData.totalEmployees += Math.floor(Math.random() * 3) - 1;
        dashboardData.overallSales += Math.floor(Math.random() * 10) - 5;
        // Ensure values don't go negative for demo
        dashboardData.totalEmployees = Math.max(0, dashboardData.totalEmployees);
        dashboardData.overallSales = Math.max(0, dashboardData.overallSales);
        updateStatsCards();
    }, 10000);
}

document.addEventListener('DOMContentLoaded', function() {
    initializeDashboard();
    // connectToFirestore(); // Uncomment if you have Firestore setup
});

window.addEventListener('resize', function() {
    if (window.innerWidth > 768) {
        document.getElementById('sidebar').classList.remove('mobile-visible');
        document.getElementById('mainContent').classList.remove('expanded');
    }
});