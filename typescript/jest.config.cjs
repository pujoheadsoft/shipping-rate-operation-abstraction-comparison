module.exports = {
  moduleNameMapper: {
    "^(\\.{1,2}/.*)\\.ts$": "$1",
  },
  testEnvironment: "node",
  testRegex: "(?:_test|\\.test)\\.ts$",
  transform: {
    "^.+\\.ts$": "babel-jest",
  },
};
