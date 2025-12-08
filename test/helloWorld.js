const HelloWorld = artifacts.require("HelloWorld");

contract("HelloWorld", () => {
    it("should set name correctly", async () => {
        const instance = await HelloWorld.deployed();
        await instance.setName("User Name");
        const name = await instance.yourName();
        assert.equal(name, "User Name");
    });
});