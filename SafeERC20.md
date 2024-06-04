# Why to use?

ERC20 standard interface outlines the function signature. It cannot enforce the return type. Some ERC20 implementations doesnt return bool on transfer/transferFrom functions, they revert.
The library handles the situations when ERC20s dont fully implement the EIP20.
Handles approval hack, with front running, by combining setting allowance to 0, then to another value
