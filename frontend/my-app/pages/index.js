import styles from "@/styles/Home.module.css";
import { ethers } from "ethers";
import { useEffect, useState, useRef } from "react";
import Web3Modal from "web3modal";
import { address, abi } from "../constants/constants";

export default function Home() {
  const [walletConnected, setWalletConnected] = useState(false);
  const [presaleStarted, setPresaleStarted] = useState(false);
  const [presaleEnded, setPresaleEnded] = useState(false);
  const [isOwner, setIsOwner] = useState(false);
  const [loading, setLoading] = useState(false);
  const [chainId, setChainId] = useState(null);
  const [numMinted, setNumMinted] = useState(0);
  const web3ModalRef = useRef();

  const mintPublicSale = async () => {
    try {
      const contractAddress = address[chainId];
      const signer = await getProviderOrSigner(true);
      const contract = new ethers.Contract(contractAddress, abi, signer);
      const tx = await contract.mint({
        value: ethers.utils.parseEther("0.01"),
      });
      setLoading(true);
      await tx.wait();
      setLoading(false);
      window.alert("You successfully minted a Crypto Dev!");
    } catch (error) {
      console.log(error.message);
    }
  };

  const mintWhitelist = async () => {
    try {
      const contractAddress = address[chainId];
      const signer = await getProviderOrSigner(true);
      const contract = new ethers.Contract(contractAddress, abi, signer);
      const tx = await contract.presaleMint({
        value: ethers.utils.parseEther("0.01"),
      });
      setLoading(true);
      await tx.wait();
      setLoading(false);
      window.alert("You successfully minted a Crypto Dev!");
    } catch (error) {
      console.log(error.message);
    }
  };

  const startPresale = async () => {
    try {
      const contractAddress = address[chainId];
      const signer = await getProviderOrSigner(true);
      const contract = new ethers.Contract(contractAddress, abi, signer);
      const tx = await contract.startPresale();
      setLoading(true);
      await tx.wait();
      setLoading(false);
    } catch (error) {
      console.log(error);
    }
  };

  const getOwner = async () => {
    try {
      const contractAddress = address[chainId];
      const provider = await getProviderOrSigner();
      const contract = new ethers.Contract(contractAddress, abi, provider);
      const signer = await getProviderOrSigner(true);
      const owner = await contract.owner();
      const signerAddress = await signer.getAddress();
      if (owner.toLowerCase() === signerAddress.toLowerCase()) {
        setIsOwner(true);
      }
    } catch (error) {
      console.log(error);
    }
  };

  const hasPresaleStarted = async () => {
    try {
      const contractAddress = address[chainId];
      if (contractAddress) {
        const provider = await getProviderOrSigner();
        const contract = new ethers.Contract(contractAddress, abi, provider);
        const presaleStartedBool = await contract.presaleStarted();
        if (!presaleStartedBool) {
          await getOwner();
        }
        setPresaleStarted(presaleStartedBool);
        return presaleStartedBool;
      } else {
        console.log(`Contract address not defined for chainId ${chainId}`);
      }
    } catch (error) {
      console.log(error);
    }
  };

  const hasPresaleEnded = async () => {
    try {
      const contractAddress = address[chainId];
      const provider = await getProviderOrSigner();
      const contract = new ethers.Contract(contractAddress, abi, provider);
      const presaleEndedNumber = await contract.presaleEnded();
      const presaleEndedBool = presaleEndedNumber.lt(
        Math.floor(Date.now() / 1000)
      );
      setPresaleEnded(presaleEndedBool);
      return presaleEndedBool;
    } catch (error) {
      console.log(error);
    }
  };

  const connectWallet = async () => {
    try {
      const testReturn = await getProviderOrSigner();
      testReturn ? setWalletConnected(true) : setWalletConnected(false);
    } catch (error) {
      console.log(error);
    }
  };

  const getProviderOrSigner = async (needSigner = false) => {
    try {
      const web3ModalRefProvider = await web3ModalRef.current.connect();
      const provider = new ethers.providers.Web3Provider(web3ModalRefProvider);
      const { chainId } = await provider.getNetwork();
      if (chainId !== 31337 && chainId !== 5) {
        window.alert("Please Connect to Goerli or Local Host!");
        throw new Error("Please Connect to Goerli or Local Host!");
      }
      setChainId(chainId);
      if (needSigner) {
        const signer = provider.getSigner();
        return signer;
      }
      return provider;
    } catch (error) {
      console.log(error);
    }
  };

  const getNumMinted = async () => {
    try {
      const contractAddress = address[chainId];
      const provider = await getProviderOrSigner();
      const contract = new ethers.Contract(contractAddress, abi, provider);
      const tokenNumber = await contract.tokenIds();
      setNumMinted(tokenNumber.toString());
    } catch (error) {
      console.log(error.message);
    }
  };

  useEffect(() => {
    if (!walletConnected) {
      web3ModalRef.current = new Web3Modal({
        network: ["https://localhost:8545", "goerli"],
        disableInjectedProvider: false,
        providerOptions: {},
      });
    }
    connectWallet();
    const _presaleStarted = hasPresaleStarted();
    if (_presaleStarted) {
      hasPresaleEnded();
    }

    getNumMinted();

    const presaleEndedInterval = setInterval(async function () {
      const _presaleStarted = await hasPresaleStarted();
      if (_presaleStarted) {
        const _presaleEnded = await hasPresaleEnded();
        if (_presaleEnded) {
          clearInterval(presaleEndedInterval);
        }
      }
    }, 5 * 1000);

    setInterval(async function () {
      await getNumMinted();
    }, 5 * 1000);
  }, [walletConnected]);

  const displayPage = () => {
    if (!walletConnected) {
      return (
        <button onClick={connectWallet} className={styles.button}>
          Connect to Metamask
        </button>
      );
    }
    if (!presaleStarted && isOwner) {
      return (
        <button onClick={startPresale} className={styles.button}>
          Start the Presale!
        </button>
      );
    } else {
      null;
    }
    if (presaleStarted && !presaleEnded) {
      return (
        <button onClick={mintWhitelist} className={styles.button}>
          Mint a CryptoDev From the Presale
        </button>
      );
    }
    if (loading) {
      return <button className={styles.button}>Loading...</button>;
    }
    if (presaleStarted && presaleEnded) {
      return (
        <button onClick={mintPublicSale} className={styles.button}>
          Mint a CryptoDev
        </button>
      );
    }
  };

  return (
    <div>
      <div className={styles.main}>
        <div>
          <h1 className={styles.title}>Welcome to Crypto Devs!</h1>
          <div className={styles.description}>
            Its an NFT collection for developers in Crypto.
          </div>
          {displayPage()}
          <span>
            <h4> {numMinted} / 20 Minted</h4>
          </span>
        </div>
      </div>

      <footer className={styles.footer}>
        Made with &#10084; by Crypto Devs
      </footer>
    </div>
  );
}
