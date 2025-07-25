---
layout: default
title: Getting Started
parent: Guides
nav_order: 1
permalink: /guides/getting-started
description: Start building AI apps in Ruby in 5 minutes. Chat, generate images, create embeddings - all with one gem.
---

# Getting Started with RubyLLM
{: .no_toc }

From zero to AI in 5 minutes. Let's build something amazing.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

After reading this guide, you will know:

*   How to install RubyLLM.
*   How to perform minimal configuration.
*   How to start a simple chat conversation.
*   How to generate an image.
*   How to create a text embedding.

## Installation

Add RubyLLM to your Gemfile:

```ruby
gem 'ruby_llm'
```

Then run `bundle install`.

(For full details, see the [Installation Guide]({% link installation.md %})).

## Minimal Configuration

RubyLLM needs API keys for the AI providers you want to use. Configure them once, typically when your application starts.

```ruby
# config/initializers/ruby_llm.rb (in Rails) or at the start of your script
require 'ruby_llm'

RubyLLM.configure do |config|
  # Add keys ONLY for the providers you intend to use.
  # Using environment variables is highly recommended.
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
  # config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
end
```

{: .note }
You only need to configure keys for the providers you actually plan to use. See the [Configuration Guide]({% link configuration.md %}) for all options, including setting defaults and connecting to custom endpoints.

## Your First Chat

Interact with language models using `RubyLLM.chat`.

```ruby
# Create a chat instance (uses the configured default model)
chat = RubyLLM.chat

# Ask a question
response = chat.ask "What is Ruby on Rails?"

# The response is a RubyLLM::Message object
puts response.content
# => "Ruby on Rails, often shortened to Rails, is a server-side web application..."
```

RubyLLM handles the conversation history automatically. See the [Chatting with AI Models Guide]({% link guides/chat.md %}) for more details.

## Generating an Image

Generate images using models like DALL-E 3 via `RubyLLM.paint`.

```ruby
# Generate an image (uses the default image model)
image = RubyLLM.paint("A photorealistic red panda coding Ruby")

# Access the image URL (or Base64 data depending on provider)
if image.url
  puts image.url
  # => "https://oaidalleapiprodscus.blob.core.windows.net/..."
else
  puts "Image data received (Base64)."
end

# Save the image locally
image.save("red_panda.png")
```

Learn more in the [Image Generation Guide]({% link guides/image-generation.md %}).

## Creating an Embedding

Create numerical vector representations of text using `RubyLLM.embed`.

```ruby
# Create an embedding (uses the default embedding model)
embedding = RubyLLM.embed("Ruby is optimized for programmer happiness.")

# Access the vector (an array of floats)
vector = embedding.vectors
puts "Vector dimension: #{vector.length}" # e.g., 1536

# Access metadata
puts "Model used: #{embedding.model}"
```

Explore further in the [Embeddings Guide]({% link guides/embeddings.md %}).

## What's Next?

You've covered the basics! Now you're ready to explore RubyLLM's features in more detail:

*   [Chatting with AI Models]({% link guides/chat.md %})
*   [Working with Models]({% link guides/models.md %}) (Choosing models, custom endpoints)
*   [Using Tools]({% link guides/tools.md %}) (Letting AI call your code)
*   [Streaming Responses]({% link guides/streaming.md %})
*   [Rails Integration]({% link guides/rails.md %})
*   [Configuration]({% link configuration.md %})
*   [Error Handling]({% link guides/error-handling.md %})