/*  Title:      Pure/General/uuid.scala
    Author:     Makarius

Universally unique identifiers.
*/

package isabelle


object UUID {
  type T = java.util.UUID

  def random(): T = java.util.UUID.randomUUID()

  def unapply(s: String): Option[T] =
    try { Some(java.util.UUID.fromString(s)) }
    catch { case _: IllegalArgumentException => None }

  def unapply(body: XML.Body): Option[T] = unapply(XML.content(body))

  def make(s: String): T =
    unapply(s).getOrElse(error("Bad UUID: " + quote(s)))
}
