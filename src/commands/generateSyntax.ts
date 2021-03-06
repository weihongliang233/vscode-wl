import * as vscode from 'vscode'
import mergeSyntax from '../syntax/mergeSyntax'
import { showMessage } from '../utilities/vsc-utils'

function getCurrentPlugins() {
  const plugins: string[] = []
  const config = vscode.workspace.getConfiguration('wolfram')
  if (config.get('syntax.simplestMode')) return
  if (config.get('syntax.xmlTemplate')) plugins.push('xml-template')
  if (config.get('syntax.typeInference')) plugins.push('type-inference')
  if (config.get('syntax.smartComments')) plugins.push('smart-comments')
  return plugins
}

function isSyntaxUpdated(plugins: string[]) {
  delete require.cache[require.resolve('../syntax')]
  const syntax = require('../syntax')
  if (!plugins) return syntax._name === 'simplest'
  if (syntax._name === 'simplest') return false
  const _plugins = new Set(syntax._plugins)
  return _plugins.size === plugins.length && plugins.every(name => _plugins.has(name))
}

export function generateSyntax(forced = false) {
  const plugins = getCurrentPlugins()
  if (!forced && isSyntaxUpdated(plugins)) {
    showMessage('The syntax file is consistent with your configuration. There is no need to regenerate.')
    return
  }
  if (plugins) {
    mergeSyntax(require('../syntaxes/basic'), plugins.map(name => require('../syntaxes/' + name)))
  } else {
    mergeSyntax(require('../syntaxes/simplest'))
  }
  showMessage('The syntax file has just been regenerated and will take effect after reload.\nDo you want to reload vscode now?', () => {
    vscode.commands.executeCommand('workbench.action.reloadWindow')
  })
}

export function checkSyntax() {
  if (!isSyntaxUpdated(getCurrentPlugins())) {
    showMessage('The syntax file currently in use is not consistent with some configurations.\nDo you want to regenerated syntax file now?', () => {
      generateSyntax(true)
    })
  }
}

checkSyntax()
