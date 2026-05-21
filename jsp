const userData = [
  { id: 1, name: "Alice", role: "admin" },
  { id: 2, name: "Bob", role: "user" },
  { id: 3, name: "Charlie", role: "admin" }
];

function getAdminNames(users) {
  return users
    .filter(user => user.role === "admin")
    .map(user => user.name);
}

const admins = getAdminNames(userData);
console.log(admins);
