import { pipeline } from "@huggingface/transformers";

let extractor;

export async function embed(text) {
  extractor ??= await pipeline("feature-extraction", "Xenova/all-MiniLM-L6-v2");
  const out = await extractor(text, { pooling: "mean", normalize: true });
  return Array.from(out.data);
}
