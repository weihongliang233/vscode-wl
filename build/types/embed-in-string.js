module.exports = {
  kind: 'scalar',
  construct(name) {
    return 'embed-in-string:' + name
  },
}