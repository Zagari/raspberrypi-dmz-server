from dotenv import load_dotenv
import os
from flask import Flask, render_template, request
from openai import OpenAI

# Initialize environment variables
load_dotenv()
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))


app = Flask(__name__)

# Securely fetch the API key using the dotenv library

dietary_restrictions = [
    "Sem Glúten",
    "Sem Lactose",
    "Vegano",
    "Pescetariano",
    "Sem Nozes",
    "Kosher",
    "Halal",
    "Baixo Carboidrato",
    "Orgânico",
    "Produzido Localmente",
]

cuisines = [
    "",
    "Italiana",
    "Mexicana",
    "Chinesa",
    "Indiana",
    "Japonesa",
    "Tailandesa",
    "Francesa",
    "Mediterrânea",
    "Americana",
    "Grega",
]


@app.route('/')
def index():
    # Display the main ingredient input page
    return render_template('index.html', cuisines=cuisines, dietary_restrictions=dietary_restrictions)


@app.route('/generate_recipe', methods=['POST'])
def generate_recipe():
    # Extract the three ingredients from the user's input
    ingredients = request.form.getlist('ingredient')

    # Extract cuisine and restrictions
    selected_cuisine = request.form.get('cuisine')
    selected_restrictions = request.form.getlist('restrictions')

    print('selected_cuisine: ' + selected_cuisine)
    print('selected_restrictions: ' + str(selected_restrictions))

    if len(ingredients) < 2:
        return "Por favor, inclua pelo menos 2 ingredientes."

    # Craft a conversational prompt for ChatGPT, specifying our needs
    prompt = f"Crie uma receita em HTML usando \
        {', '.join(ingredients)}. Tudo bem usar outros ingredientes necessários. \
        Certifique-se de que os ingredientes da receita apareçam no topo, \
        seguidos pelas instruções passo a passo."

    if selected_cuisine:
        prompt += f"A culinária deve ser {selected_cuisine}."

    if selected_restrictions and len(selected_restrictions) > 0:
        prompt += f" A receita deve ter as seguintes restrições: {', '.join(selected_restrictions)}."

    print('prompt: ' + prompt)

    messages = [{'role': 'user', 'content': prompt}]

    # Engage ChatGPT to receive the desired recipe
    response = client.chat.completions.create(model="gpt-3.5-turbo",
                                              messages=messages,
                                              temperature=0.8,
                                              top_p=1.0,
                                              frequency_penalty=0.0,
                                              presence_penalty=0.6)

    # Extract the recipe from ChatGPT's response
    recipe = response.choices[0].message.content

    # Showcase the recipe on a new page
    return render_template('recipe.html', recipe=recipe)


if __name__ == '__main__':
    app.run(debug=True)
