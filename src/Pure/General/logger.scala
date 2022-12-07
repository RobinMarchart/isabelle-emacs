/*  Title:      Pure/General/logger.scala
    Author:     Makarius

Minimal logging support.
*/

package isabelle


object Logger {
  def make(log_file: Option[Path]): Logger =
    log_file match { case Some(file) => new File_Logger(file) case None => No_Logger }

  def make(progress: Progress): Logger =
    new Logger { def apply(msg: => String): Unit = progress.echo(msg) }
}

trait Logger {
  def apply(msg: => String): Unit

  def timeit[A](body: => A,
    message: Exn.Result[A] => String = null,
    enabled: Boolean = true
  ): A = Timing.timeit(body, message = message, enabled = enabled, output = apply(_))
}

object No_Logger extends Logger {
  def apply(msg: => String): Unit = {}
}

class File_Logger(path: Path) extends Logger {
  def apply(msg: => String): Unit = synchronized { File.append(path, msg + "\n") }

  override def toString: String = path.toString
}
