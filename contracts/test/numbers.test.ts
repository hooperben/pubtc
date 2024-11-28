import { parseEther } from "ethers";

describe("testing number representations", async () => {
  const amountsToTest = [
    "1.11",
    "2.1",
    "10.12112",
    "5.12112",
    "8.7",
    "0.0000005",
    "200.00000",
    "123.2841",
    "199.99999",
  ];

  it("should work as expected", () => {
    const convertFromHexToArray = (rawInput: string): Uint8Array => {
      const formattedInput = rawInput.startsWith("0x")
        ? rawInput.slice(2)
        : rawInput;

      const evenFormattedInput =
        formattedInput.length % 2 === 0 ? formattedInput : "0" + formattedInput;

      return Uint8Array.from(Buffer.from(evenFormattedInput, "hex"));
    };

    for (const amountToTest of amountsToTest) {
      const depositAmount = parseEther(amountToTest);
      const rawAmountHex = convertFromHexToArray(depositAmount.toString(16));

      const rawAmountBigInt = BigInt(
        "0x" +
          Array.from(rawAmountHex)
            .map((item) => item.toString(16).padStart(2, "0"))
            .join(""),
      );

      console.log("------NEW_AMOUNT-----");

      // Debugging logs
      console.log(`Testing amount: ${amountToTest}`);
      console.log(`Deposit Amount (hex): ${depositAmount.toString(16)}`);
      console.log(`Raw Amount BigInt (hex): ${rawAmountBigInt.toString(16)}`);

      if (depositAmount.toString(16) !== rawAmountBigInt.toString(16)) {
        console.log("-----------");
        console.log(amountToTest, " representation incorrect");
      }
    }
  });
});
