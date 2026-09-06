---
title: Une autre façon de construire le web
summary: Commencer par les mots. Ajouter un peu de structure. Laisser le navigateur faire son travail.
slug: a-quieter-web
locale: fr
date: 2026-09-06T00:00:00Z
tags: [Développement, Design]
---
Les meilleurs outils laissent de la place au travail. Une page doit être soignée avant d'être compliquée : un titre clair, une largeur de lecture confortable et une raison de poursuivre.

Ce journal commence par du **Markdown**, et non par des paragraphes écrits dans une vue. Les mots vivent dans un fichier ; Swift apporte la mise en page, le thème et la route.

## Commencer par le contenu

Le texte brut réduit la distance entre une idée et sa publication. On peut relire une phrase dans un diff et déplacer une section sans modifier la vue.

- Structurer le récit avec des titres.
- Mettre en valeur les expressions importantes.
- Choisir des liens descriptifs et utiles.

> De bons choix par défaut rendent les choses ordinaires plus simples.

## Une base simple et typée

Robin transforme le document en composants sémantiques. Un titre reste un titre ; une liste reste une liste. L'application choisit la présentation.

```swift
Heading { "Bonjour, le monde !" }
Text { "Un peu moins de mécanismes." }
```

Le titre, le résumé, la langue et la date de publication viennent des métadonnées au début de ce fichier.

## À vous de jouer

Modifiez cet article, ajustez les tokens dans `Theme.swift`, puis reconstruisez le site. Aucune feuille de style séparée n'est à synchroniser.

Pour découvrir le projet, consultez la [page À propos](/fr/about).
