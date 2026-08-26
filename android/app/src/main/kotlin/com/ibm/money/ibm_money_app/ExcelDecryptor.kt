package com.ibm.money.ibm_money_app

import java.io.ByteArrayInputStream
import org.apache.poi.poifs.crypt.Decryptor
import org.apache.poi.poifs.crypt.EncryptionInfo
import org.apache.poi.poifs.filesystem.POIFSFileSystem

class InvalidExcelPasswordException : Exception()

object ExcelDecryptor {
    fun decrypt(bytes: ByteArray, password: String): ByteArray {
        POIFSFileSystem(ByteArrayInputStream(bytes)).use { fileSystem ->
            val info = EncryptionInfo(fileSystem)
            val decryptor = Decryptor.getInstance(info)
            if (!decryptor.verifyPassword(password)) {
                throw InvalidExcelPasswordException()
            }
            return decryptor.getDataStream(fileSystem).use { input ->
                input.readBytes()
            }
        }
    }
}
